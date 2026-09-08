from __future__ import annotations

import os
import sys
from datetime import date, timedelta
from typing import Any

from .config import Config
from .timeutil import parse_rfc3339

BLOCKS = "▁▂▃▄▅▆▇█"
RESET = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"


def want_color(color: bool | None = None) -> bool:
    if os.environ.get("NO_COLOR"):
        return False
    if color is False:
        return False
    if color is True:
        return True
    return sys.stdout.isatty()


def _c(enabled: bool, text: str, *styles: str) -> str:
    if not enabled or not styles:
        return text
    return "".join(styles) + text + RESET


def sparkline(values: list[int], *, color: bool = False) -> str:
    if not values:
        return ""
    peak = max(max(values), 1)
    last = len(BLOCKS) - 1
    chars: list[str] = []
    for i, value in enumerate(values):
        if value <= 0:
            ch = "▁"
        else:
            idx = min(last, int(round((value / peak) * last)))
            ch = BLOCKS[idx]
        if color and i == len(values) - 1:
            ch = _c(True, ch, BOLD)
        chars.append(ch)
    return "".join(chars)


def target_bar(count: int, maximum: int, width: int = 10) -> str:
    maximum = max(maximum, 1)
    filled = int(round(min(max(count, 0), maximum) / maximum * width))
    filled = min(max(filled, 0), width)
    return "█" * filled + "░" * (width - filled)


def _ordered_counts(series: dict[str, int], end_day: date, num_days: int = 14) -> list[int]:
    start = end_day - timedelta(days=num_days - 1)
    return [
        int(series.get((start + timedelta(days=i)).isoformat(), 0))
        for i in range(num_days)
    ]


def _fmt_github(value: int | None) -> str:
    return "?" if value is None else str(value)


def _clock(updated_at: str | None) -> str:
    dt = parse_rfc3339(updated_at)
    if dt is None:
        return ""
    return dt.strftime("%H:%M")


def _heading(day: date) -> str:
    return f"{day.strftime('%a')} {day.day} {day.strftime('%b')}  IST"


def _target_status(count: int, lo: int, hi: int) -> str:
    if count < lo:
        return "under"
    if count > hi:
        return "over"
    return "in range"


def render(
    snapshot: dict[str, Any],
    cfg: Config,
    *,
    footer: bool = False,
    color: bool | None = None,
) -> str:
    on = want_color(color)
    day = date.fromisoformat(snapshot["date"])
    tasks = snapshot.get("tasks") or {}
    commits = snapshot.get("commits") or {}
    series = snapshot.get("series") or {}
    errors = snapshot.get("errors") or []

    local_n = int(commits.get("local") or 0)
    github_n = commits.get("github")
    github_n_int = github_n if isinstance(github_n, int) else None
    unpushed = int(commits.get("unpushed_hint") or 0)
    scored = local_n if cfg.commit_target_on != "github" else (github_n_int or 0)
    status = _target_status(scored, cfg.commit_target_min, cfg.commit_target_max)
    status_style = YELLOW if status == "under" else (DIM if status == "over" else GREEN)
    bar = target_bar(scored, cfg.commit_target_max)

    lines: list[str] = [
        f"  {_heading(day)}",
        _c(on, "  ─────────────────────────────", DIM),
    ]

    if tasks.get("ok"):
        overdue = int(tasks.get("overdue") or 0)
        overdue_s = _c(on, f"{overdue:>2}", RED if overdue else DIM)
        lines.append(
            f"  {_c(on, 'tasks', DIM)}     "
            f"done {int(tasks.get('completed') or 0):>2}   "
            f"open {int(tasks.get('pending') or 0):>2}   "
            f"overdue {overdue_s}"
        )
    else:
        hint = next((e for e in errors if str(e).startswith("tasks:")), "tasks: unavailable")
        msg = hint.removeprefix("tasks: ").strip()
        if len(msg) > 48:
            msg = msg[:45] + "..."
        lines.append(f"  {_c(on, 'tasks', DIM)}     ({msg})")

    lines.append(
        f"  {_c(on, 'commits', DIM)}   "
        f"local {local_n:<3} github {_fmt_github(github_n_int):<3} "
        f"target {cfg.commit_target_min}–{cfg.commit_target_max}"
    )
    lines.append(f"            {bar}  {_c(on, status, status_style)}")
    if cfg.github and unpushed > 0:
        lines.append(f"            unpushed {unpushed}")

    leftover = tasks.get("leftover_by_list") or {}
    if leftover:
        lines.append("")
        lines.append(f"  {_c(on, 'leftovers', DIM)}")
        width = min(max(max(len(name) for name in leftover), 4), 22)
        for name, count in leftover.items():
            label = name if len(name) <= width else name[: width - 1] + "…"
            lines.append(f"    {label:<{width}}  {int(count):>3}")

    local_vals = _ordered_counts(series.get("local") or {}, day)
    gh_vals = _ordered_counts(series.get("github") or {}, day)
    lines.append("")
    lines.append(f"  14d  local   {sparkline(local_vals, color=on)}")
    if cfg.github:
        lines.append(f"       github  {sparkline(gh_vals, color=on)}")

    shown_errors = [e for e in errors if not (tasks.get("ok") and str(e).startswith("tasks:"))]
    if not tasks.get("ok"):
        shown_errors = [e for e in errors if not str(e).startswith("tasks:")]
    if shown_errors:
        lines.append("")
        for err in shown_errors:
            lines.append(f"  {_c(on, str(err), RED)}")

    clock = _clock(snapshot.get("updated_at"))
    foot = []
    if clock:
        foot.append(clock)
    if footer:
        foot.append("q close  r refresh")
    if foot:
        lines.append("")
        lines.append("  " + _c(on, "   ".join(foot), DIM))

    return "\n".join(lines) + "\n"
