from __future__ import annotations

import sys

from .collect import snapshot
from .config import load_config
from .render import render
from .selftest import run as run_selftest
from .tasks import auth_google
from .tui import watch

HELP = """\
scoreboard — daily Tasks + git glance (IST)

commands:
  show       snapshot and print (default)
  watch      refresh loop (i3 overlay)
  snapshot   write today's JSON, one-line log
  auth       Google Tasks via gcloud (preferred)
  selftest   run local unit checks

Google: `scoreboard auth` runs gcloud login with Tasks readonly
and enables the Tasks API on your GCP project. Desktop OAuth JSON
is only a fallback if gcloud is missing.

GitHub: uses the existing `gh` CLI. Local git uses git_roots in
  ~/.config/scoreboard/config.toml
User overrides (not overwritten by Home Manager):
  ~/.config/scoreboard/local.toml
"""


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    cmd = args[0] if args else "show"
    if cmd in ("-h", "--help", "help"):
        sys.stdout.write(HELP)
        return 0
    if cmd == "selftest":
        return run_selftest()

    cfg = load_config()
    if cmd in ("show",):
        snap = snapshot(cfg)
        sys.stdout.write(render(snap, cfg, footer=False))
        return 0
    if cmd in ("watch", "--watch"):
        return watch(cfg)
    if cmd == "snapshot":
        snap = snapshot(cfg)
        commits = snap.get("commits") or {}
        tasks = snap.get("tasks") or {}
        print(
            snap["date"],
            "done",
            tasks.get("completed"),
            "pend",
            tasks.get("pending"),
            "over",
            tasks.get("overdue"),
            "local",
            commits.get("local"),
            "github",
            commits.get("github"),
        )
        for err in snap.get("errors") or []:
            print("!", err, file=sys.stderr)
        return 0
    if cmd == "auth":
        return auth_google(cfg)
    print("unknown command:", cmd, file=sys.stderr)
    print("try: scoreboard --help", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
