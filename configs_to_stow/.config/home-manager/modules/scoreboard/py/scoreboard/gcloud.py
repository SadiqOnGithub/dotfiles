from __future__ import annotations

import shutil
import subprocess


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
        out, err = _run(["auth", "print-access-token"])
    if err:
        return None, err
    token = out.splitlines()[0].strip() if out else ""
    if not token:
        return None, "gcloud print-access-token returned empty"
    return token, None


def current_project() -> str | None:
    out, err = _run(["config", "get-value", "project"])
    if err or not out or out in ("(unset)", "None"):
        return None
    return out.splitlines()[0].strip()


def login() -> int:
    binary = gcloud_bin()
    if not binary:
        print("gcloud is not on PATH. Add google-cloud-sdk via Home Manager and switch.")
        return 1
    print("Logging into gcloud (browser).")
    login = subprocess.run(
        [binary, "auth", "login", "--brief", "--update-adc"],
        check=False,
    )
    if login.returncode != 0:
        return login.returncode
    print("Requesting Tasks readonly on application-default credentials (browser).")
    adc = subprocess.run(
        [
            binary,
            "auth",
            "application-default",
            "login",
            f"--scopes={LOGIN_SCOPES}",
        ],
        check=False,
    )
    return adc.returncode


def ensure_project(preferred: str = "sadiq-scoreboard") -> tuple[str | None, str | None]:
    existing = current_project()
    if existing:
        return existing, None
    _, err = _run(["projects", "create", preferred, "--name=scoreboard"], timeout=120)
    if err and "already exists" not in err.lower() and "409" not in err:
        listed, list_err = _run(["projects", "list", "--format=value(projectId)", "--limit=1"])
        if list_err or not listed:
            return None, err
        project = listed.splitlines()[0].strip()
    else:
        project = preferred
    _, err = _run(["config", "set", "project", project])
    if err:
        return None, err
    return project, None


def enable_tasks_api(project: str) -> str | None:
    _, err = _run(
        ["services", "enable", "tasks.googleapis.com", "--project", project],
        timeout=180,
    )
    return err
