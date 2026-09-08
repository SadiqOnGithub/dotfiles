from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from .config import Config
from .github import collect_github
from .gitlocal import collect_local
from .store import load_day, load_json, merge_completed, save_day, save_json
from .tasks import classify_tasks, fetch_tasks
from .timeutil import now_tz, today


def _series_counts(buckets: dict[str, list[Any]]) -> dict[str, int]:
    return {day: len(items) for day, items in buckets.items()}


def _empty_series(end_day: date, num_days: int = 14) -> dict[str, int]:
    start = end_day - timedelta(days=num_days - 1)
    return {(start + timedelta(days=i)).isoformat(): 0 for i in range(num_days)}


def snapshot(cfg: Config) -> dict[str, Any]:
    tz_name = cfg.timezone
    day = today(tz_name)
    previous = load_day(cfg.data_dir, day)
    errors: list[str] = []

    completed_items: list[dict[str, Any]] = []
    pending = 0
    overdue = 0
    leftover: dict[str, int] = {}
    tasks_ok = False
    tasks, tasks_err = fetch_tasks(cfg)
    if tasks_err:
        errors.append(f"tasks: {tasks_err}")
        if previous and previous.get("tasks"):
            prev_tasks = previous["tasks"]
            completed_items = list(prev_tasks.get("completed_items") or [])
            pending = int(prev_tasks.get("pending") or 0)
            overdue = int(prev_tasks.get("overdue") or 0)
            leftover = dict(prev_tasks.get("leftover_by_list") or {})
    else:
        assert tasks is not None
        new_completed, pending, overdue, leftover, open_ids = classify_tasks(
            tasks, day, tz_name
        )
        completed_items = merge_completed(previous, new_completed, open_ids)
        tasks_ok = True

    local_buckets = collect_local(cfg.expand_roots(), cfg.git_author_emails, tz_name, day)
    local_series = _series_counts(local_buckets)
    local_today = local_buckets.get(day.isoformat(), [])

    gh_series = _empty_series(day)
    github_ok = False
    github_cached_today = False
    gh_today_shas: list[str] = []
    cache_path = cfg.data_dir / "github-cache.json"
    if cfg.github:
        gh_buckets, gh_err = collect_github(tz_name, day)
        if gh_err:
            errors.append(f"github: {gh_err}")
            cached = load_json(cache_path)
            if cached and cached.get("series"):
                gh_series = {**gh_series, **cached["series"]}
            if cached and cached.get("date") == day.isoformat():
                gh_today_shas = list(cached.get("shas_today") or [])
                github_cached_today = True
        else:
            gh_series = _series_counts(gh_buckets)
            gh_today_shas = [c.sha for c in gh_buckets.get(day.isoformat(), [])]
            github_ok = True
            save_json(
                cache_path,
                {
                    "fetched_at": now_tz(tz_name).isoformat(),
                    "date": day.isoformat(),
                    "series": gh_series,
                    "shas_today": gh_today_shas,
                },
            )

    local_shas = {c.sha for c in local_today}
    unpushed = len(local_shas - set(gh_today_shas)) if cfg.github else 0
    if not cfg.github:
        github_count = None
    elif github_ok or github_cached_today:
        github_count = len(gh_today_shas)
    else:
        github_count = None

    leftover_sorted = dict(sorted(leftover.items(), key=lambda kv: (-kv[1], kv[0])))

    snap: dict[str, Any] = {
        "date": day.isoformat(),
        "tz": tz_name,
        "updated_at": now_tz(tz_name).isoformat(),
        "tasks": {
            "ok": tasks_ok,
            "completed": len(completed_items),
            "pending": pending,
            "overdue": overdue,
            "leftover_by_list": leftover_sorted,
            "completed_items": completed_items,
        },
        "commits": {
            "local": len(local_today),
            "github": github_count,
            "unpushed_hint": unpushed,
            "github_ok": github_ok,
        },
        "series": {
            "local": local_series,
            "github": gh_series,
        },
        "errors": errors,
    }
    save_day(cfg.data_dir, snap)
    return snap
