from __future__ import annotations

import select
import sys
import termios
import tty

from .collect import snapshot
from .config import Config
from .render import render, want_color

# Alternate screen so each paint replaces the frame instead of stacking
# copies in terminal scrollback when the glance is taller than the window.
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


def _read_byte(fd: int, timeout: float | None) -> str | None:
    if timeout is not None:
        ready, _, _ = select.select([fd], [], [], timeout)
        if not ready:
            return None
    ch = sys.stdin.read(1)
    return ch if ch else ""


def _skip_escape(fd: int) -> None:
    """Drop CSI / SS3 / mouse payloads that follow ESC (wheel, arrows, etc.)."""
    nxt = _read_byte(fd, 0.05)
    if nxt is None or nxt == "":
        return
    if nxt == "[":
        third = _read_byte(fd, 0.05)
        if third is None or third == "":
            return
        if third == "M":
            for _ in range(3):
                if _read_byte(fd, 0.05) in (None, ""):
                    return
            return
        if third == "<":
            while True:
                b = _read_byte(fd, 0.05)
                if b is None or b in ("", "M", "m"):
                    return
            return
        if len(third) == 1 and "@" <= third <= "~":
            return
        while True:
            b = _read_byte(fd, 0.05)
            if b is None or b == "" or (len(b) == 1 and "@" <= b <= "~"):
                return
        return
    if nxt == "O":
        _read_byte(fd, 0.05)


def _key(fd: int) -> str:
    """One key. Wheel/arrow sequences return '\\x00' (ignore). EOF is ''."""
    ch = sys.stdin.read(1)
    if not ch:
        return ""
    if ch != "\x1b":
        return ch
    ready, _, _ = select.select([fd], [], [], 0.05)
    if not ready:
        return "\x1b"
    _skip_escape(fd)
    return "\x00"


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
            while True:
                ready, _, _ = select.select([sys.stdin], [], [], max(cfg.poll_seconds, 5))
                if not ready:
                    break
                char = _key(fd)
                if char in ("", "q", "Q", "\x1b"):
                    return 0
                if char in ("r", "R"):
                    _paint("refreshing…\n")
                    break
                # ignore scroll / arrows / leftover bytes; keep the current frame
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        if entered_alt:
            sys.stdout.write(_ALT_OFF)
        else:
            sys.stdout.write("\033[0m")
        sys.stdout.flush()
    return 0
