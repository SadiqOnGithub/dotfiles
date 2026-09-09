from __future__ import annotations

import json
from datetime import date
from pathlib import Path
from typing import Any


def day_path(data_dir: Path, day: date) -> Path:
    return data_dir / "days" / f"{day.isoformat()}.json"


def load_day(data_dir: Path, day: date) -> dict[str, Any] | None:
    path = day_path(data_dir, day)
    if not path.is_file():
        return None
    try:
        with path.open() as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def save_day(data_dir: Path, snapshot: dict[str, Any]) -> Path:
    path = day_path(data_dir, date.fromisoformat(snapshot["date"]))
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".json.tmp")
    with tmp.open("w") as fh:
        json.dump(snapshot, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    tmp.replace(path)
    return path


def load_json(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    try:
        with path.open() as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def save_json(path: Path, data: dict[str, Any], *, mode: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    tmp.replace(path)
    if mode is not None:
        path.chmod(mode)


def merge_recent(
    old: list[dict[str, Any]],
    new: list[dict[str, Any]],
    *,
    id_key: str,
    time_key: str,
    limit: int,
) -> list[dict[str, Any]]:
    by_id: dict[str, dict[str, Any]] = {}
    for item in old + new:
        item_id = item.get(id_key)
        if item_id:
            by_id[str(item_id)] = item
    return sorted(
        by_id.values(),
        key=lambda item: str(item.get(time_key) or ""),
        reverse=True,
    )[:limit]


def merge_completed(
    previous: dict[str, Any] | None,
    new_items: list[dict[str, Any]],
    open_ids: set[str],
) -> list[dict[str, Any]]:
    """Union of completed-today items. Drop IDs that are open again in Google."""
    by_id: dict[str, dict[str, Any]] = {}
    if previous:
        for item in previous.get("tasks", {}).get("completed_items", []):
            item_id = item.get("id")
            if item_id and item_id not in open_ids:
                by_id[item_id] = item
    for item in new_items:
        item_id = item.get("id")
        if item_id:
            by_id[item_id] = item
    return list(by_id.values())
