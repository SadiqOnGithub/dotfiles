from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Any

from . import gcloud as gcloud_auth
from .config import Config
from .http import http_json, with_query
from .timeutil import as_tz_date, due_calendar_date, parse_rfc3339

TASKS_BASE = "https://tasks.googleapis.com/tasks/v1"


@dataclass
class Task:
    id: str
    title: str
    list_title: str
    status: str
    due: str | None
    completed: str | None


def access_token(cfg: Config) -> tuple[str | None, str | None]:
    return gcloud_auth.access_token()


def quota_project(cfg: Config) -> str | None:
    if cfg.google_quota_project:
        return cfg.google_quota_project
    return gcloud_auth.current_project()


def auth_google(cfg: Config) -> int:
    if gcloud_auth.login(cfg.client_path) != 0:
        print("gcloud ADC login failed.")
        return 1
    project = quota_project(cfg)
    if not project:
        print("No GCP project set. In local.toml:")
        print('  google_quota_project = "gen-lang-client-0236258077"')
        print("or: gcloud config set project PROJECT_ID")
        return 1
    print("Using GCP project:", project)
    api_err = gcloud_auth.enable_tasks_api(project)
    if api_err:
        print("Could not enable Tasks API:", api_err)
        return 1
    token, err = gcloud_auth.access_token()
    if err or not token:
        print("gcloud has no ADC token:", err)
        return 1
    lists, err = _paginate(
        f"{TASKS_BASE}/users/@me/lists", token, "items", quota_project=project
    )
    if err:
        print("Tasks API check failed:", err)
        print("Add your Google account as an OAuth test user, then retry.")
        return 1
    nlists = len(lists or [])
    print(f"Tasks API ok ({nlists} list{'s' if nlists != 1 else ''}).")
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


def recent_closed(tasks: list[Task], limit: int = 10) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for task in tasks:
        if task.status != "completed" or not task.completed:
            continue
        items.append(
            {
                "id": task.id,
                "title": task.title,
                "list": task.list_title,
                "completed": task.completed,
            }
        )
    items.sort(key=lambda item: item["completed"], reverse=True)
    return items[:limit]
