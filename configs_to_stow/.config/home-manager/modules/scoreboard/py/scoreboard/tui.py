from __future__ import annotations

import select
import sys
import termios
import tty

from .collect import snapshot
from .config import Config
from .render import render, want_color

# Alternate screen so each paint replaces the frame instead of stacking
# copies in Ghostty scrollback when the glance is taller than the window.
_ALT_ON = "\033[?1049h\033[?25l"
_ALT_OFF = "\033[?25h\033[?1049l\033[0m"
_CLEAR = "\033[H\033[2J\033[3J"


def set_title(title: str) -> None:
    sys.stdout.write(f"\033]0;{title}\007")
    sys.stdout.flush()


def _paint(text: str) -> None:
    sys.stdout.write(_CLEAR)
    sys.stdout.write(text)
    if not text.endswith("\n"):
        sys.stdout.write("\n")
    sys.stdout.flush()


def _drain(fd: int) -> None:
    while True:
        ready, _, _ = select.select([fd], [], [], 0)
        if not ready:
            return
        if not sys.stdin.read(1):
            return


def watch(cfg: Config) -> int:
    set_title("scoreboard")
    if not sys.stdin.isatty():
        snap = snapshot(cfg)
        sys.stdout.write(render(snap, cfg, footer=False, color=want_color()))
        return 0

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    entered_alt = False
    try:
        tty.setcbreak(fd)
        sys.stdout.write(_ALT_ON)
        entered_alt = True
        _paint("loading…\n")
        while True:
            snap = snapshot(cfg)
            _paint(render(snap, cfg, footer=True, color=want_color()))
            ready, _, _ = select.select([sys.stdin], [], [], max(cfg.poll_seconds, 5))
            if not ready:
                continue
            char = sys.stdin.read(1)
            _drain(fd)
            if char in ("", "q", "Q", "\x1b"):
                break
            if char not in ("r", "R"):
                continue
            _paint("refreshing…\n")
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        if entered_alt:
            sys.stdout.write(_ALT_OFF)
        else:
            sys.stdout.write("\033[0m")
        sys.stdout.flush()
    return 0
