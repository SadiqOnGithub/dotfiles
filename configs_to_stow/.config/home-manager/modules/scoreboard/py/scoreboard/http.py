from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


def http_json(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    body: dict[str, Any] | None = None,
    form: dict[str, str] | None = None,
    timeout: int = 30,
) -> tuple[Any, str | None]:
    data: bytes | None = None
    req_headers = dict(headers or {})
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        req_headers.setdefault("Content-Type", "application/x-www-form-urlencoded")
    elif body is not None:
        data = json.dumps(body).encode()
        req_headers.setdefault("Content-Type", "application/json")
    request = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as exc:
        err_body = exc.read().decode("utf-8", "replace")
        return None, f"HTTP {exc.code}: {err_body[:240]}"
    except urllib.error.URLError as exc:
        return None, str(exc.reason)
    if not raw:
        return {}, None
    try:
        return json.loads(raw), None
    except json.JSONDecodeError:
        return None, "response was not json"


def with_query(url: str, **params: str | None) -> str:
    parts = urllib.parse.urlsplit(url)
    query = dict(urllib.parse.parse_qsl(parts.query, keep_blank_values=True))
    for key, value in params.items():
        if value is None:
            query.pop(key, None)
        else:
            query[key] = value
    return urllib.parse.urlunsplit(parts._replace(query=urllib.parse.urlencode(query)))
