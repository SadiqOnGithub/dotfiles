from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from .config import Config

BLOCKS = "▁▂▃▄▅▆▇█"


def sparkline(values: list[int]) -> str:
    if not values:
        return ""
    peak = max(max(values), 1)
    chars: list[str] = []
    last = len(BLOCKS) - 1
    for value in values:
        if value <= 0:
            chars.append("▁")
            continue
        idx = min(last, int(round((value / peak) * last)))
        chars.append(BLOCKS[idx])
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


def render(snapshot: dict[str, Any], cfg: Config, *, footer: bool = False) -> str:
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
    bar = target_bar(scored, cfg.commit_target_max)

    lines: list[str] = [
        f"TODAY  {snapshot['date']}  IST",
        "────────────────────────────────",
    ]

    if tasks.get("ok"):
        lines.append(
            f"TASKS     done {tasks.get('completed', 0):<4} "
            f"pending {tasks.get('pending', 0):<4} "
            f"overdue {tasks.get('overdue', 0)}"
        )
    else:
        hint = next((e for e in errors if str(e).startswith("tasks:")), "tasks: unavailable")
        msg = hint.removeprefix("tasks: ").strip()
        if len(msg) > 58:
            msg = msg[:55] + "..."
        lines.append(f"TASKS     ({msg})")

    lines.append(
        f"COMMITS   local {local_n:<4} github {_fmt_github(github_n_int):<4} "
        f"target {cfg.commit_target_min}–{cfg.commit_target_max}"
    )
    extra = f"unpushed ~{unpushed}" if cfg.github else ""
    lines.append(f"          {extra:<16}{bar}  ({cfg.commit_target_on})")

    leftover = tasks.get("leftover_by_list") or {}
    if leftover:
        lines.append("")
        lines.append("leftovers")
        width = max(len(name) for name in leftover)
        width = min(max(width, 4), 22)
        for name, count in leftover.items():
            label = name if len(name) <= width else name[: width - 1] + "…"
            lines.append(f"  {label:<{width}}  {count}")

    local_vals = _ordered_counts(series.get("local") or {}, day)
    gh_vals = _ordered_counts(series.get("github") or {}, day)
    lines.append("")
    lines.append(f"14d local     {sparkline(local_vals)}")
    if cfg.github:
        lines.append(f"14d github    {sparkline(gh_vals)}")

    if errors:
        lines.append("")
        for err in errors:
            lines.append(f"! {err}")

    updated = snapshot.get("updated_at")
    if updated:
        lines.append("")
        lines.append(f"updated {updated}")

    if footer:
        lines.append("")
        lines.append("q close   r refresh")

    return "\n".join(lines) + "\n"
