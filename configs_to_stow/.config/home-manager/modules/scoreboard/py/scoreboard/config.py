from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    tomllib = None  # type: ignore[assignment]


def xdg_config() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))


def xdg_data() -> Path:
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))


@dataclass
class Config:
    timezone: str = "Asia/Kolkata"
    commit_target_min: int = 5
    commit_target_max: int = 10
    commit_target_on: str = "local"
    git_author_emails: list[str] = field(
        default_factory=lambda: ["sadiqonemail@gmail.com"]
    )
    git_roots: list[str] = field(
        default_factory=lambda: ["~/dotfiles", "~/Documents", "~/Arduino"]
    )
    github: bool = True
    poll_seconds: int = 30
    google_client_path: str = ""
    google_token_path: str = ""
    google_quota_project: str = ""

    config_path: Path = field(init=False)
    data_dir: Path = field(init=False)

    def __post_init__(self) -> None:
        self.config_path = Path(
            os.environ.get("SCOREBOARD_CONFIG", xdg_config() / "scoreboard" / "config.toml")
        )
        self.data_dir = Path(
            os.environ.get("SCOREBOARD_DATA", xdg_data() / "scoreboard")
        )
        if not self.google_client_path:
            self.google_client_path = str(
                xdg_config() / "scoreboard" / "google-client.json"
            )
        if not self.google_token_path:
            self.google_token_path = str(self.data_dir / "google-token.json")

    @property
    def client_path(self) -> Path:
        return Path(os.path.expanduser(self.google_client_path))

    @property
    def token_path(self) -> Path:
        return Path(os.path.expanduser(self.google_token_path))

    def expand_roots(self) -> list[Path]:
        roots: list[Path] = []
        for raw in self.git_roots:
            path = Path(os.path.expanduser(raw))
            if path.exists():
                roots.append(path)
        return roots


_OVERRIDE_KEYS = (
    "timezone",
    "commit_target_min",
    "commit_target_max",
    "commit_target_on",
    "git_author_emails",
    "git_roots",
    "github",
    "poll_seconds",
    "google_client_path",
    "google_token_path",
    "google_quota_project",
)


def _apply_toml(cfg: Config, path: Path) -> None:
    if tomllib is None or not path.is_file():
        return
    with path.open("rb") as fh:
        data = tomllib.load(fh)
    for key in _OVERRIDE_KEYS:
        if key in data:
            setattr(cfg, key, data[key])


def load_config(path: Path | None = None) -> Config:
    cfg = Config()
    cfg_path = path or cfg.config_path
    _apply_toml(cfg, cfg_path)
    local = cfg_path.parent / "local.toml"
    if local != cfg_path:
        _apply_toml(cfg, local)
    cfg.config_path = cfg_path
    cfg.data_dir.mkdir(parents=True, exist_ok=True)
    return cfg
