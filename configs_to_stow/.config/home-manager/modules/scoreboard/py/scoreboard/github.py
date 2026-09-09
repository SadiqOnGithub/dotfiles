from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from urllib.parse import quote

from .timeutil import as_tz_date, parse_rfc3339


@dataclass(frozen=True)
class GhCommit:
    sha: str
    author_date: datetime
    repo: str
    message: str


def _run_gh(args: list[str], timeout: int = 45) -> tuple[str, str | None]:
    try:
        proc = subprocess.run(
            ["gh", *args],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError:
        return "", "gh not installed"
    except subprocess.TimeoutExpired:
        return "", "gh timed out"
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "gh failed").strip().splitlines()
        return "", err[-1][:240] if err else "gh failed"
    return proc.stdout, None


def _parse_items(stdout: str) -> list[dict]:
    text = stdout.strip()
    if not text:
        return []
    decoder = json.JSONDecoder()
    idx = 0
    objects: list[object] = []
    while idx < len(text):
        while idx < len(text) and text[idx].isspace():
            idx += 1
        if idx >= len(text):
            break
        try:
            obj, end = decoder.raw_decode(text, idx)
        except json.JSONDecodeError:
            break
        objects.append(obj)
        idx = end
    if len(objects) == 1 and isinstance(objects[0], dict) and "items" in objects[0]:
        items = objects[0]["items"]
        return items if isinstance(items, list) else []
    if len(objects) == 1 and isinstance(objects[0], list):
        return [x for x in objects[0] if isinstance(x, dict)]
    return [x for x in objects if isinstance(x, dict)]


def github_login() -> tuple[str | None, str | None]:
    stdout, err = _run_gh(["api", "user", "--jq", ".login"], timeout=15)
    if err:
        return None, err
    login = stdout.strip().strip('"')
    if not login:
        return None, "gh api user: empty login"
    return login, None


def collect_github(
    tz_name: str, end_day: date, num_days: int = 14
) -> tuple[dict[str, list[GhCommit]], str | None]:
    start_day = end_day - timedelta(days=num_days - 1)
    login, err = github_login()
    if err or not login:
        return {}, err or "gh login missing"
    q_start = start_day - timedelta(days=1)
    q_end = end_day + timedelta(days=1)
    query = f"author:{login} author-date:{q_start.isoformat()}..{q_end.isoformat()}"
    path = f"/search/commits?q={quote(query)}&per_page=100"
    stdout, err = _run_gh(["api", "--paginate", path, "--jq", ".items[]"])
    if err:
        return {}, err
    buckets: dict[str, list[GhCommit]] = {
        (start_day + timedelta(days=i)).isoformat(): [] for i in range(num_days)
    }
    for item in _parse_items(stdout):
        sha = str(item.get("sha") or "")
        commit = item.get("commit") or {}
        author = commit.get("author") or {}
        dt = parse_rfc3339(author.get("date"))
        full = ((item.get("repository") or {}).get("full_name")) or ""
        repo = full.rsplit("/", 1)[-1] if full else ""
        message = str(commit.get("message") or "").split("\n", 1)[0].strip()
        if not sha or dt is None:
            continue
        key = as_tz_date(dt, tz_name).isoformat()
        if key in buckets:
            buckets[key].append(
                GhCommit(sha=sha, author_date=dt, repo=repo, message=message)
            )
    for key, commits in buckets.items():
        seen: set[str] = set()
        unique: list[GhCommit] = []
        for commit in commits:
            if commit.sha in seen:
                continue
            seen.add(commit.sha)
            unique.append(commit)
        buckets[key] = unique
    return buckets, None
