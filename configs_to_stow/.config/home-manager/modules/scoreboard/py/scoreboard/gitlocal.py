from __future__ import annotations

import subprocess
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path

from .timeutil import as_tz_date, day_bounds, parse_rfc3339


@dataclass(frozen=True)
class LocalCommit:
    sha: str
    author_date: datetime
    repo: str


def discover_repos(roots: list[Path]) -> list[Path]:
    repos: list[Path] = []
    seen: set[Path] = set()

    def add(path: Path) -> None:
        try:
            resolved = path.resolve()
        except OSError:
            return
        if resolved in seen:
            return
        if (resolved / ".git").exists():
            seen.add(resolved)
            repos.append(resolved)

    for root in roots:
        if not root.exists():
            continue
        add(root)
        if root.is_dir() and not (root / ".git").exists():
            try:
                children = list(root.iterdir())
            except OSError:
                continue
            for child in children:
                if child.is_dir() and not child.name.startswith("."):
                    add(child)
    return repos


def _git_log(repo: Path, emails: list[str], since: datetime) -> list[LocalCommit]:
    cmd = [
        "git",
        "-C",
        str(repo),
        "log",
        "--all",
        "--pretty=format:%H\t%aI",
        "--since",
        since.isoformat(),
    ]
    for email in emails:
        cmd.append(f"--author={email}")
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=20, check=False
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return []
    if proc.returncode != 0 or not proc.stdout.strip():
        return []
    commits: list[LocalCommit] = []
    for line in proc.stdout.splitlines():
        if "\t" not in line:
            continue
        sha, iso = line.split("\t", 1)
        dt = parse_rfc3339(iso)
        if dt is None:
            continue
        commits.append(LocalCommit(sha=sha.strip(), author_date=dt, repo=str(repo)))
    return commits


def collect_local(
    roots: list[Path],
    emails: list[str],
    tz_name: str,
    end_day: date,
    num_days: int = 14,
) -> dict[str, list[LocalCommit]]:
    start_day = end_day - timedelta(days=num_days - 1)
    start, _ = day_bounds(start_day, tz_name)
    slack = start - timedelta(days=2)
    buckets: dict[str, list[LocalCommit]] = {
        (start_day + timedelta(days=i)).isoformat(): [] for i in range(num_days)
    }
    for repo in discover_repos(roots):
        for commit in _git_log(repo, emails, slack):
            key = as_tz_date(commit.author_date, tz_name).isoformat()
            if key in buckets:
                buckets[key].append(commit)
    for key, commits in buckets.items():
        seen: set[str] = set()
        unique: list[LocalCommit] = []
        for commit in commits:
            if commit.sha in seen:
                continue
            seen.add(commit.sha)
            unique.append(commit)
        buckets[key] = unique
    return buckets
