from __future__ import annotations

import json
import webbrowser
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse

from .config import Config
from . import gcloud as gcloud_auth
from .http import http_json, with_query
from .store import save_json
from .timeutil import as_tz_date, due_calendar_date, parse_rfc3339

SCOPE = "https://www.googleapis.com/auth/tasks.readonly"
AUTH_URI = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URI = "https://oauth2.googleapis.com/token"
TASKS_BASE = "https://tasks.googleapis.com/tasks/v1"


@dataclass
class Task:
    id: str
    title: str
    list_title: str
    status: str
    due: str | None
    completed: str | None


def load_client(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    try:
        raw = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(raw, dict):
        return None
    for key in ("installed", "web"):
        if isinstance(raw.get(key), dict):
            return raw[key]
    return raw


def _load_token(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def _save_token(path: Path, token: dict[str, Any]) -> None:
    save_json(path, token, mode=0o600)


def _token_expiry(token: dict[str, Any]) -> datetime | None:
    raw = token.get("expires_at")
    if not raw:
        return None
    return parse_rfc3339(str(raw))


def exchange_code(client: dict[str, Any], code: str, redirect_uri: str) -> tuple[dict[str, Any] | None, str | None]:
    data, err = http_json(
        "POST",
        TOKEN_URI,
        form={
            "code": code,
            "client_id": client["client_id"],
            "client_secret": client.get("client_secret", ""),
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        },
    )
    if err or not isinstance(data, dict):
        return None, err or "token exchange failed"
    return _normalize_token(data), None


def refresh_token(client: dict[str, Any], token: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    refresh = token.get("refresh_token")
    if not refresh:
        return None, "no refresh_token; run scoreboard auth"
    data, err = http_json(
        "POST",
        TOKEN_URI,
        form={
            "refresh_token": str(refresh),
            "client_id": client["client_id"],
            "client_secret": client.get("client_secret", ""),
            "grant_type": "refresh_token",
        },
    )
    if err or not isinstance(data, dict):
        return None, err or "token refresh failed"
    merged = _normalize_token(data)
    if "refresh_token" not in merged:
        merged["refresh_token"] = refresh
    return merged, None


def _normalize_token(data: dict[str, Any]) -> dict[str, Any]:
    expires_in = int(data.get("expires_in") or 0)
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=max(expires_in - 60, 0))
    out = {
        "access_token": data.get("access_token"),
        "refresh_token": data.get("refresh_token"),
        "token_type": data.get("token_type", "Bearer"),
        "expires_at": expires_at.isoformat(),
        "scope": data.get("scope"),
    }
    return {k: v for k, v in out.items() if v is not None}


def access_token(cfg: Config) -> tuple[str | None, str | None]:
    token, err = gcloud_auth.access_token()
    if token:
        return token, None
    gcloud_err = err

    client = load_client(cfg.client_path)
    if client is None:
        hint = gcloud_err or "gcloud not ready"
        return None, f"{hint} — run: scoreboard auth"
    token_data = _load_token(cfg.token_path)
    if token_data is None:
        return None, "not authed — run: scoreboard auth"
    expiry = _token_expiry(token_data)
    now = datetime.now(timezone.utc)
    if expiry is None or expiry <= now:
        token_data, err = refresh_token(client, token_data)
        if err or token_data is None:
            return None, err
        _save_token(cfg.token_path, token_data)
    access = token_data.get("access_token")
    if not access:
        return None, "token missing access_token; run scoreboard auth"
    return str(access), None


def quota_project(cfg: Config) -> str | None:
    if cfg.google_quota_project:
        return cfg.google_quota_project
    return gcloud_auth.current_project()


def auth_google(cfg: Config) -> int:
    if gcloud_auth.gcloud_bin():
        return _auth_gcloud(cfg)
    return _auth_desktop(cfg)


def _auth_gcloud(cfg: Config) -> int:
    if gcloud_auth.login() != 0:
        print("gcloud auth login failed.")
        return 1
    project, err = gcloud_auth.ensure_project()
    if err or not project:
        print("Could not set a GCP project:", err)
        print("Create one in the console, then: gcloud config set project PROJECT_ID")
        return 1
    print("Using GCP project:", project)
    api_err = gcloud_auth.enable_tasks_api(project)
    if api_err:
        print("Could not enable Tasks API:", api_err)
        return 1
    token, err = gcloud_auth.access_token()
    if err or not token:
        print("gcloud has no access token:", err)
        return 1
    lists, err = _paginate(
        f"{TASKS_BASE}/users/@me/lists", token, "items", quota_project=project
    )
    if err:
        print("Tasks API check failed:", err)
        print("If this is a 403, add your Google account as an OAuth test user")
        print("on the project's consent screen, then re-run scoreboard auth.")
        return 1
    nlists = len(lists or [])
    print(f"Tasks API ok ({nlists} list{'s' if nlists != 1 else ''}).")
    print("scoreboard will use: gcloud auth print-access-token")
    return 0


def _auth_desktop(cfg: Config) -> int:
    client = load_client(cfg.client_path)
    if client is None:
        print(
            "gcloud is not installed. Either install google-cloud-sdk and re-run\n"
            "scoreboard auth, or save a Desktop OAuth client JSON to:\n"
            f"  {cfg.client_path}"
        )
        return 1

    holder: dict[str, str | None] = {"code": None, "error": None}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802
            query = parse_qs(urlparse(self.path).query)
            holder["code"] = (query.get("code") or [None])[0]
            holder["error"] = (query.get("error") or [None])[0]
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            if holder["code"]:
                self.wfile.write(b"Authorized. You can close this tab.")
            else:
                self.wfile.write(b"Authorization failed. You can close this tab.")

        def log_message(self, fmt: str, *args: object) -> None:
            return

    httpd = HTTPServer(("127.0.0.1", 0), Handler)
    port = httpd.server_address[1]
    redirect_uri = f"http://127.0.0.1:{port}/"
    params = {
        "client_id": client["client_id"],
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": SCOPE,
        "access_type": "offline",
        "prompt": "consent",
    }
    url = AUTH_URI + "?" + urlencode(params)
    print("Opening browser for Google Tasks (readonly).")
    print(url)
    webbrowser.open(url)
    httpd.timeout = 180
    httpd.handle_request()
    if holder["error"]:
        print("Google returned error:", holder["error"])
        return 1
    if not holder["code"]:
        print("No authorization code received (timed out?).")
        return 1
    token, err = exchange_code(client, holder["code"], redirect_uri)
    if err or token is None:
        print("Token exchange failed:", err)
        return 1
    cfg.token_path.parent.mkdir(parents=True, exist_ok=True)
    _save_token(cfg.token_path, token)
    print("Saved token to", cfg.token_path)
    return 0


def _auth_header(token: str, quota_project: str | None = None) -> dict[str, str]:
    headers = {"Authorization": f"Bearer {token}"}
    if quota_project:
        headers["x-goog-user-project"] = quota_project
    return headers


def _paginate(
    url: str,
    token: str,
    key: str,
    *,
    quota_project: str | None = None,
) -> tuple[list[dict[str, Any]] | None, str | None]:
    items: list[dict[str, Any]] = []
    page_url = url
    for _ in range(50):
        data, err = http_json(
            "GET", page_url, headers=_auth_header(token, quota_project)
        )
        if err or not isinstance(data, dict):
            return None, err or "tasks api failed"
        chunk = data.get(key) or []
        if isinstance(chunk, list):
            items.extend(x for x in chunk if isinstance(x, dict))
        next_token = data.get("nextPageToken")
        if not next_token:
            return items, None
        page_url = with_query(url, pageToken=str(next_token))
    return items, "tasks api pagination overflow"


def fetch_tasks(cfg: Config) -> tuple[list[Task] | None, str | None]:
    token, err = access_token(cfg)
    if err or not token:
        return None, err
    project = quota_project(cfg)
    lists, err = _paginate(
        f"{TASKS_BASE}/users/@me/lists", token, "items", quota_project=project
    )
    if err or lists is None:
        return None, err
    tasks: list[Task] = []
    for tasklist in lists:
        list_id = str(tasklist.get("id") or "")
        list_title = str(tasklist.get("title") or "list")
        if not list_id:
            continue
        url = with_query(
            f"{TASKS_BASE}/lists/{list_id}/tasks",
            showCompleted="true",
            showHidden="true",
            showDeleted="false",
            maxResults="100",
        )
        items, err = _paginate(url, token, "items", quota_project=project)
        if err or items is None:
            return None, err
        for item in items:
            if item.get("deleted"):
                continue
            task_id = str(item.get("id") or "")
            if not task_id:
                continue
            tasks.append(
                Task(
                    id=task_id,
                    title=str(item.get("title") or "(untitled)"),
                    list_title=list_title,
                    status=str(item.get("status") or "needsAction"),
                    due=str(item["due"]) if item.get("due") else None,
                    completed=str(item["completed"]) if item.get("completed") else None,
                )
            )
    return tasks, None


def classify_tasks(
    tasks: list[Task], day: date, tz_name: str
) -> tuple[list[dict[str, Any]], int, int, dict[str, int], set[str]]:
    completed_today: list[dict[str, Any]] = []
    pending = 0
    overdue = 0
    leftover: dict[str, int] = {}
    open_ids: set[str] = set()
    for task in tasks:
        if task.status == "completed":
            completed_at = parse_rfc3339(task.completed)
            if completed_at is not None and as_tz_date(completed_at, tz_name) == day:
                completed_today.append(
                    {
                        "id": task.id,
                        "title": task.title,
                        "list": task.list_title,
                        "completed": task.completed,
                    }
                )
            continue
        open_ids.add(task.id)
        leftover[task.list_title] = leftover.get(task.list_title, 0) + 1
        due_day = due_calendar_date(task.due)
        if due_day is not None and due_day < day:
            overdue += 1
        else:
            pending += 1
    return completed_today, pending, overdue, leftover, open_ids
