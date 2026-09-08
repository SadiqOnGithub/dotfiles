from __future__ import annotations

import os
import subprocess
import tempfile
from datetime import date, datetime, timezone
from pathlib import Path

from .gitlocal import collect_local, discover_repos
from .render import sparkline, target_bar
from .store import merge_completed
from .tasks import Task, classify_tasks
from .timeutil import as_tz_date, day_bounds, due_calendar_date, parse_rfc3339


class Failure(Exception):
    pass


def _check(cond: bool, msg: str) -> None:
    if not cond:
        raise Failure(msg)


def test_due_is_utc_calendar_date() -> None:
    # Midnight UTC on 8 Sep must stay 8 Sep, not 7 Sep IST.
    due = due_calendar_date("2026-09-08T00:00:00.000Z")
    _check(due == date(2026, 9, 8), f"due calendar date was {due}")
    overdue_on = date(2026, 9, 8)
    _check(due is not None and due >= overdue_on, "due today must not be overdue")
    yesterday = due_calendar_date("2026-09-07T00:00:00.000Z")
    _check(yesterday == date(2026, 9, 7), f"yesterday due was {yesterday}")
    _check(yesterday is not None and yesterday < overdue_on, "7 Sep should be overdue on 8 Sep")


def test_completed_uses_ist() -> None:
    # 2026-09-07 20:00 UTC = 2026-09-08 01:30 IST
    dt = parse_rfc3339("2026-09-07T20:00:00Z")
    _check(dt is not None, "parse failed")
    _check(as_tz_date(dt, "Asia/Kolkata") == date(2026, 9, 8), "expected IST next day")


def test_day_bounds() -> None:
    start, end = day_bounds(date(2026, 9, 8), "Asia/Kolkata")
    _check(str(start) == "2026-09-08 00:00:00+05:30", f"start {start}")
    _check(str(end) == "2026-09-09 00:00:00+05:30", f"end {end}")


def test_classify() -> None:
    day = date(2026, 9, 8)
    tasks = [
        Task("a", "done today", "Work", "completed", None, "2026-09-08T10:00:00+05:30"),
        Task("b", "open", "Work", "needsAction", None, None),
        Task("c", "late", "Home", "needsAction", "2026-09-07T00:00:00.000Z", None),
        Task("d", "due today", "Home", "needsAction", "2026-09-08T00:00:00.000Z", None),
        Task("e", "done yesterday", "Work", "completed", None, "2026-09-07T10:00:00+05:30"),
    ]
    completed, pending, overdue, leftover, open_ids = classify_tasks(
        tasks, day, "Asia/Kolkata"
    )
    _check(len(completed) == 1 and completed[0]["id"] == "a", f"completed {completed}")
    _check(pending == 2, f"pending {pending}")
    _check(overdue == 1, f"overdue {overdue}")
    _check(leftover == {"Work": 1, "Home": 2}, f"leftover {leftover}")
    _check(open_ids == {"b", "c", "d"}, f"open {open_ids}")


def test_merge_completed_union_and_untick() -> None:
    prev = {
        "tasks": {
            "completed_items": [
                {"id": "a", "title": "old"},
                {"id": "b", "title": "will untick"},
            ]
        }
    }
    merged = merge_completed(
        prev,
        [{"id": "c", "title": "new"}],
        open_ids={"b"},
    )
    ids = sorted(item["id"] for item in merged)
    _check(ids == ["a", "c"], f"merged ids {ids}")


def test_sparkline_and_bar() -> None:
    line = sparkline([0, 1, 5, 10])
    _check(len(line) == 4, f"sparkline {line!r}")
    bar = target_bar(5, 10, width=10)
    _check(bar == "█████░░░░░", f"bar {bar!r}")
    _check(target_bar(0, 10, 10) == "░░░░░░░░░░", "empty bar")
    _check(target_bar(12, 10, 10) == "██████████", "over-target bar")


def test_discover_and_local_git() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        repo = root / "repo"
        repo.mkdir()
        env = {
            **os.environ,
            "GIT_AUTHOR_NAME": "sadiq",
            "GIT_AUTHOR_EMAIL": "sadiqonemail@gmail.com",
            "GIT_COMMITTER_NAME": "sadiq",
            "GIT_COMMITTER_EMAIL": "sadiqonemail@gmail.com",
        }
        subprocess.run(["git", "init"], cwd=repo, check=True, capture_output=True)
        (repo / "f").write_text("x\n")
        subprocess.run(["git", "add", "f"], cwd=repo, check=True, capture_output=True, env=env)
        subprocess.run(
            ["git", "commit", "-m", "t"],
            cwd=repo,
            check=True,
            capture_output=True,
            env=env,
        )
        found = discover_repos([root])
        _check(repo.resolve() in found, f"discover {found}")
        day = datetime.now(timezone.utc).date()
        buckets = collect_local(
            [root],
            ["sadiqonemail@gmail.com"],
            "Asia/Kolkata",
            day,
            num_days=14,
        )
        # Count across the 14-day window; the commit is "now".
        total = sum(len(v) for v in buckets.values())
        _check(total == 1, f"expected 1 local commit, got {total} {buckets}")


def run() -> int:
    tests = [
        test_due_is_utc_calendar_date,
        test_completed_uses_ist,
        test_day_bounds,
        test_classify,
        test_merge_completed_union_and_untick,
        test_sparkline_and_bar,
        test_discover_and_local_git,
    ]
    failed = 0
    for test in tests:
        try:
            test()
            print(f"ok  {test.__name__}")
        except Failure as exc:
            failed += 1
            print(f"FAIL {test.__name__}: {exc}")
        except Exception as exc:  # pragma: no cover
            failed += 1
            print(f"FAIL {test.__name__}: {type(exc).__name__}: {exc}")
    print(f"{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0
