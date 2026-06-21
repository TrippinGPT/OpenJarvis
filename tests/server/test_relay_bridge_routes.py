from __future__ import annotations

import json
import subprocess
from pathlib import Path
from types import SimpleNamespace

from fastapi import FastAPI
from fastapi.testclient import TestClient

from openjarvis.server import relay_bridge_routes


def _client() -> TestClient:
    app = FastAPI()
    app.include_router(relay_bridge_routes.router)
    return TestClient(app)


def _write_manifest(path: Path, openclaw_root: Path) -> None:
    path.write_text(
        json.dumps(
            {
                "relay_name": "Trippin AI Relay",
                "openclaw_root": str(openclaw_root),
                "integration_mode": "read_only_bridge",
                "safety_rules": ["Read only."],
                "lanes": [{"name": "SignalForge"}],
            }
        ),
        encoding="utf-8",
    )


def test_status_uses_fixed_read_only_git_commands(
    tmp_path: Path, monkeypatch
) -> None:
    openclaw_root = tmp_path / "OPENCLAW"
    openclaw_root.mkdir()
    manifest_path = tmp_path / "relay_project_lanes.json"
    _write_manifest(manifest_path, openclaw_root)
    monkeypatch.setattr(relay_bridge_routes, "MANIFEST_PATH", manifest_path)

    calls: list[tuple[list[str], dict]] = []
    outputs = iter(["", "feature-test\n", "abc123 First\ndef456 Second\n"])

    def fake_run(command, **kwargs):
        calls.append((command, kwargs))
        return SimpleNamespace(returncode=0, stdout=next(outputs), stderr="")

    monkeypatch.setattr(relay_bridge_routes.subprocess, "run", fake_run)

    response = _client().get("/api/relay/openclaw-bridge/status")

    assert response.status_code == 200
    payload = response.json()
    assert payload["openclaw_exists"] is True
    assert payload["openclaw_git_branch"] == "feature-test"
    assert payload["openclaw_git_status_short"] == []
    assert payload["openclaw_recent_commits"] == ["abc123 First", "def456 Second"]
    assert [call[0] for call in calls] == [
        ["git", "-C", str(openclaw_root), "status", "--short"],
        ["git", "-C", str(openclaw_root), "branch", "--show-current"],
        [
            "git",
            "-C",
            str(openclaw_root),
            "--no-pager",
            "log",
            "--oneline",
            "-5",
        ],
    ]
    assert all(call[1]["shell"] is False for call in calls)
    assert all(call[1]["timeout"] == 5 for call in calls)


def test_status_handles_missing_manifest(tmp_path: Path, monkeypatch) -> None:
    missing_manifest = tmp_path / "missing.json"
    monkeypatch.setattr(relay_bridge_routes, "MANIFEST_PATH", missing_manifest)

    response = _client().get("/api/relay/openclaw-bridge/status")

    assert response.status_code == 200
    payload = response.json()
    assert payload["integration_mode"] == "unavailable"
    assert payload["lanes"] == []
    assert "manifest not found" in payload["warning"].lower()


def test_status_handles_missing_openclaw_without_running_git(
    tmp_path: Path, monkeypatch
) -> None:
    openclaw_root = tmp_path / "missing-openclaw"
    manifest_path = tmp_path / "relay_project_lanes.json"
    _write_manifest(manifest_path, openclaw_root)
    monkeypatch.setattr(relay_bridge_routes, "MANIFEST_PATH", manifest_path)

    def fail_run(*args, **kwargs):
        raise AssertionError("Git must not run when OpenClaw is missing")

    monkeypatch.setattr(relay_bridge_routes.subprocess, "run", fail_run)

    response = _client().get("/api/relay/openclaw-bridge/status")

    assert response.status_code == 200
    payload = response.json()
    assert payload["openclaw_exists"] is False
    assert "folder was not found" in payload["warning"].lower()


def test_git_timeout_returns_warning(monkeypatch) -> None:
    def timeout(*args, **kwargs):
        raise subprocess.TimeoutExpired(cmd=args[0], timeout=5)

    monkeypatch.setattr(relay_bridge_routes.subprocess, "run", timeout)

    lines, warning = relay_bridge_routes._run_git(["git", "--version"])

    assert lines == []
    assert warning == "Git status check timed out after 5 seconds."
