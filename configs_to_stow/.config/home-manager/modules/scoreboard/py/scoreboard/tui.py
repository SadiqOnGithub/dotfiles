from __future__ import annotations

import select
import sys
import termios
import tty

from .collect import snapshot
from .config import Config
from .render import render, want_color


def set_title(title: str) -> None:
    sys.stdout.write(f"\033]0;{title}\007")
    sys.stdout.flush()


def watch(cfg: Config) -> int:
    set_title("scoreboard")
    if not sys.stdin.isatty():
        snap = snapshot(cfg)
        sys.stdout.write(render(snap, cfg, footer=False, color=want_color()))
        return 0

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        sys.stdout.write("\033[2J\033[Hloading…\n")
        sys.stdout.flush()
        while True:
            snap = snapshot(cfg)
            sys.stdout.write("\033[2J\033[H")
            sys.stdout.write(render(snap, cfg, footer=True, color=want_color()))
            sys.stdout.flush()
            ready, _, _ = select.select([sys.stdin], [], [], max(cfg.poll_seconds, 5))
            if not ready:
                continue
            char = sys.stdin.read(1)
            if char in ("q", "Q", "\x1b"):
                break
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write("\033[0m")
        sys.stdout.flush()
    return 0
