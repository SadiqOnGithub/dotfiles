from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

TASKS_SCOPE = "https://www.googleapis.com/auth/tasks.readonly"
LOGIN_SCOPES = ",".join(
    [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/userinfo.email",
        TASKS_SCOPE,
    ]
)


def gcloud_bin() -> str | None:
    return shutil.which("gcloud")


def _run(args: list[str], *, timeout: int = 60) -> tuple[str, str | None]:
    binary = gcloud_bin()
    if not binary:
        return "", "gcloud not installed"
    try:
        proc = subprocess.run(
            [binary, *args],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return "", "gcloud timed out"
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "gcloud failed").strip().splitlines()
        return "", err[-1][:240] if err else "gcloud failed"
    return proc.stdout.strip(), None


def access_token() -> tuple[str | None, str | None]:
    out, err = _run(["auth", "application-default", "print-access-token"])
    if err:
        return None, err
    token = out.splitlines()[0].strip() if out else ""
    if not token:
        return None, "gcloud ADC token empty — run: scoreboard auth"
    return token, None


def current_project() -> str | None:
    out, err = _run(["config", "get-value", "project"])
    if err or not out or out in ("(unset)", "None"):
        return None
    return out.splitlines()[0].strip()


def login(client_json: Path) -> int:
    binary = gcloud_bin()
    if not binary:
        print("gcloud is not on PATH.")
        return 1
    if not client_json.is_file():
        print("Missing Desktop OAuth client JSON:")
        print(f"  {client_json}")
        return 1
    print("Opening browser for Tasks readonly (your Desktop client).")
    proc = subprocess.run(
        [
            binary,
            "auth",
            "application-default",
            "login",
            f"--client-id-file={client_json}",
            f"--scopes={LOGIN_SCOPES}",
        ],
        check=False,
    )
    return proc.returncode


def enable_tasks_api(project: str) -> str | None:
    _, err = _run(
        ["services", "enable", "tasks.googleapis.com", "--project", project],
        timeout=180,
    )
    return err
