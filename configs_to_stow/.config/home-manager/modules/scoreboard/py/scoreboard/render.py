from __future__ import annotations

import os
import sys
from datetime import date, datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

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


def _when(value: str | datetime | None, tz_name: str) -> str:
    if isinstance(value, datetime):
        dt = value
    else:
        dt = parse_rfc3339(value)
    if dt is None:
        return ""
    return dt.astimezone(ZoneInfo(tz_name)).strftime("%d %b %H:%M")


def _clip(text: str, width: int) -> str:
    text = text.replace("\n", " ").strip()
    if len(text) <= width:
        return text
    return text[: width - 1] + "…"


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


def _stamp(value: str | datetime | None, tz_name: str, on: bool) -> str:
    when = _when(value, tz_name)
    return _c(on, f"{when:<12}", DIM) if when else " " * 12


def _closed_cell(item: dict[str, Any], tz_name: str, on: bool, title_w: int = 28) -> str:
    title = _clip(str(item.get("title") or "(untitled)"), title_w)
    return f"{title:<{title_w}}  {_stamp(item.get('completed'), tz_name, on)}"


def _pushed_cell(item: dict[str, Any], tz_name: str, on: bool, title_w: int = 22) -> str:
    title = _clip(str(item.get("message") or item.get("sha") or ""), title_w)
    repo = _clip(str(item.get("repo") or ""), 10)
    return f"{title:<{title_w}}  {_stamp(item.get('date'), tz_name, on)}  {repo:<10}"


def _feeds(
    closed: list[dict[str, Any]],
    pushed: list[dict[str, Any]],
    tz_name: str,
    on: bool,
) -> list[str]:
    if not closed and not pushed:
        return []
    out = [""]
    if closed and pushed:
        # Side by side so the glance still fits the overlay after a refresh.
        left_w = 28 + 2 + 12
        gap = 3
        pad = 4 + left_w + gap - 2 - len("closed")
        out.append(f"  {_c(on, 'closed', DIM)}{' ' * pad}{_c(on, 'pushed', DIM)}")
        n = max(len(closed), len(pushed))
        for i in range(n):
            left = _closed_cell(closed[i], tz_name, on) if i < len(closed) else " " * left_w
            right = _pushed_cell(pushed[i], tz_name, on) if i < len(pushed) else ""
            out.append(f"    {left}{' ' * gap}{right}".rstrip())
        return out
    if closed:
        out.append(f"  {_c(on, 'closed', DIM)}")
        for item in closed:
            out.append(f"    {_closed_cell(item, tz_name, on, title_w=36)}")
        return out
    out.append(f"  {_c(on, 'pushed', DIM)}")
    for item in pushed:
        out.append(f"    {_pushed_cell(item, tz_name, on, title_w=28)}")
    return out


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

    tz_name = str(snapshot.get("tz") or cfg.timezone)
    closed = list(snapshot.get("recent_closed") or [])[:10]
    pushed = list(snapshot.get("recent_github") or [])[:10]
    lines.extend(_feeds(closed, pushed, tz_name, on))

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
