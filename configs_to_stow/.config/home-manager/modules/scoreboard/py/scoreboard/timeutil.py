from __future__ import annotations

from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

UTC = timezone.utc


def zone(tz_name: str) -> ZoneInfo:
    return ZoneInfo(tz_name)


def now_tz(tz_name: str) -> datetime:
    return datetime.now(zone(tz_name))


def today(tz_name: str) -> date:
    return now_tz(tz_name).date()


def day_bounds(day: date, tz_name: str) -> tuple[datetime, datetime]:
    start = datetime.combine(day, time.min, tzinfo=zone(tz_name))
    return start, start + timedelta(days=1)


def parse_rfc3339(value: str | None) -> datetime | None:
    if not value:
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=UTC)
    return dt


def as_tz_date(dt: datetime, tz_name: str) -> date:
    return dt.astimezone(zone(tz_name)).date()


def due_calendar_date(due: str | None) -> date | None:
    """Google Tasks `due` is a date stored as midnight UTC. Use that UTC date."""
    dt = parse_rfc3339(due)
    if dt is None:
        return None
    return dt.astimezone(UTC).date()
