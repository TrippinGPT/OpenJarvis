"""Tests for the Relay placeholder voice routes."""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import MagicMock

import pytest

fastapi = pytest.importorskip("fastapi")

from fastapi import FastAPI  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from openjarvis.speech.tts import TTSResult  # noqa: E402


@pytest.fixture
def voice_config_path(tmp_path: Path) -> Path:
    path = tmp_path / "relay_voice_profiles.json"
    path.write_text(
        json.dumps(
            {
                "default_voice": "smartmouth_relay",
                "active_tts_voice": "af_bella",
                "active_tts_mode": "sarcastic",
                "active_placeholder_style": "sarcastic_polish_04",
                "secondary_placeholder_style": "sarcastic_polish_03",
                "backup_placeholder_style": "sarcastic_polish_02",
                "voices": [
                    {
                        "id": "smartmouth_relay",
                        "display_name": "Smartmouth Relay",
                        "public_label": "Relay Companion",
                        "alternate_public_label": "Relay Voice",
                    }
                ],
            }
        ),
        encoding="utf-8",
    )
    return path


@pytest.fixture
def app_with_voice_routes(monkeypatch, voice_config_path: Path):
    from openjarvis.server import relay_voice_routes

    fake_backend = MagicMock()
    fake_backend.backend_id = "kokoro"
    fake_backend.health.return_value = True
    fake_backend.synthesize.return_value = TTSResult(
        audio=b"RIFFfakewavdata",
        format="wav",
        voice_id="af_bella",
        sample_rate=24000,
    )

    monkeypatch.setattr(relay_voice_routes, "VOICE_CONFIG_PATH", voice_config_path)
    monkeypatch.setattr(relay_voice_routes, "_kokoro_backend", lambda: fake_backend)

    app = FastAPI()
    app.include_router(relay_voice_routes.router)
    return app


@pytest.fixture
def client(app_with_voice_routes):
    return TestClient(app_with_voice_routes)


def test_relay_voice_config_endpoint(client):
    response = client.get("/api/relay/voice/config")
    assert response.status_code == 200
    data = response.json()
    assert data["active_voice"] == "af_bella"
    assert data["active_mode"] == "sarcastic"
    assert data["active_placeholder_style"] == "sarcastic_polish_04"
    assert data["manual_only"] is True
    assert data["autoplay"] is False


def test_relay_voice_play_endpoint(client):
    response = client.post("/api/relay/voice/play", json={})
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("audio/wav")
    assert response.headers["x-relay-placeholder-voice"] == "af_bella"
    assert response.content.startswith(b"RIFF")


def test_relay_voice_play_endpoint_returns_clean_error(monkeypatch, voice_config_path: Path):
    from openjarvis.server import relay_voice_routes

    fake_backend = MagicMock()
    fake_backend.backend_id = "kokoro"
    fake_backend.health.return_value = True
    fake_backend.synthesize.side_effect = RuntimeError("kokoro offline")

    monkeypatch.setattr(relay_voice_routes, "VOICE_CONFIG_PATH", voice_config_path)
    monkeypatch.setattr(relay_voice_routes, "_kokoro_backend", lambda: fake_backend)

    app = FastAPI()
    app.include_router(relay_voice_routes.router)
    client = TestClient(app)

    response = client.post("/api/relay/voice/play", json={})
    assert response.status_code == 503
    assert response.json()["detail"] == "Relay placeholder voice synthesis failed: kokoro offline"
