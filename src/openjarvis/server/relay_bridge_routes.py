"""Read-only Relay/OpenClaw bridge status endpoint."""

from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from fastapi import APIRouter

router = APIRouter(prefix="/api/relay/openclaw-bridge", tags=["relay-bridge"])

MANIFEST_PATH = (
    Path(__file__).resolve().parents[3] / "config" / "relay_project_lanes.json"
)
GIT_TIMEOUT_SECONDS = 5


def _checked_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _empty_response(warning: str) -> dict[str, Any]:
    return {
        "relay_name": "",
        "openclaw_root": "",
        "integration_mode": "unavailable",
        "safety_rules": [],
        "lanes": [],
        "openclaw_exists": False,
        "openclaw_git_branch": None,
        "openclaw_git_status_short": [],
        "openclaw_recent_commits": [],
        "checked_at": _checked_at(),
        "warning": warning,
    }


def _load_manifest() -> tuple[dict[str, Any] | None, str | None]:
    if not MANIFEST_PATH.is_file():
        return None, f"Relay bridge manifest not found: {MANIFEST_PATH}"

    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return None, f"Relay bridge manifest could not be loaded: {exc}"

    required = (
        "relay_name",
        "openclaw_root",
        "integration_mode",
        "safety_rules",
        "lanes",
    )
    missing = [field for field in required if field not in manifest]
    if missing:
        return None, f"Relay bridge manifest is missing fields: {', '.join(missing)}"

    return manifest, None


def _run_git(command: list[str]) -> tuple[list[str], str | None]:
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=GIT_TIMEOUT_SECONDS,
            check=False,
            shell=False,
        )
    except FileNotFoundError:
        return [], "Git is not installed or is not available on PATH."
    except subprocess.TimeoutExpired:
        return [], f"Git status check timed out after {GIT_TIMEOUT_SECONDS} seconds."
    except OSError as exc:
        return [], f"Git status check failed to start: {exc}"

    if result.returncode != 0:
        detail = result.stderr.strip() or f"exit code {result.returncode}"
        return [], f"Git status check failed: {detail}"

    return result.stdout.splitlines(), None


@router.get("/status")
async def openclaw_bridge_status() -> dict[str, Any]:
    """Return manifest data and a fixed set of read-only OpenClaw Git checks."""
    manifest, manifest_warning = _load_manifest()
    if manifest is None:
        warning = manifest_warning or "Relay bridge manifest is unavailable."
        return _empty_response(warning)

    openclaw_root = Path(str(manifest["openclaw_root"]))
    response: dict[str, Any] = {
        "relay_name": manifest["relay_name"],
        "openclaw_root": str(openclaw_root),
        "integration_mode": manifest["integration_mode"],
        "safety_rules": manifest["safety_rules"],
        "lanes": manifest["lanes"],
        "openclaw_exists": openclaw_root.is_dir(),
        "openclaw_git_branch": None,
        "openclaw_git_status_short": [],
        "openclaw_recent_commits": [],
        "checked_at": _checked_at(),
        "warning": None,
    }

    if not response["openclaw_exists"]:
        response["warning"] = f"OpenClaw folder was not found: {openclaw_root}"
        return response

    commands = {
        "openclaw_git_status_short": [
            "git",
            "-C",
            str(openclaw_root),
            "status",
            "--short",
        ],
        "openclaw_git_branch": [
            "git",
            "-C",
            str(openclaw_root),
            "branch",
            "--show-current",
        ],
        "openclaw_recent_commits": [
            "git",
            "-C",
            str(openclaw_root),
            "--no-pager",
            "log",
            "--oneline",
            "-5",
        ],
    }

    warnings: list[str] = []
    for field, command in commands.items():
        lines, warning = _run_git(command)
        if warning:
            warnings.append(warning)
            continue
        if field == "openclaw_git_branch":
            response[field] = lines[0] if lines else None
        else:
            response[field] = lines

    if warnings:
        response["warning"] = " ".join(warnings)

    return response


__all__ = ["router"]
