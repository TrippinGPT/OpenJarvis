"""Read-only Relay placeholder voice config and manual local TTS playback."""

from __future__ import annotations

import json
import random
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

router = APIRouter(prefix="/api/relay/voice", tags=["relay-voice"])

VOICE_CONFIG_PATH = Path(__file__).resolve().parents[3] / "config" / "relay_voice_profiles.json"
PLACEHOLDER_LINES = {
    "sarcastic_polish_04": "Relax. I already fixed it.",
    "sarcastic_polish_03": "We HAVE a plan. Miracles happen...",
    "sarcastic_polish_02": "Routing now. Don't screw it up...",
}
PLACEHOLDER_CATEGORY_LINES = {
    "startup": [
        "Relay online. Try not to break anything expensive.",
        "Relay online. Keep the damage optional.",
    ],
    "routing": [
        "Routing now. Don't screw it up...",
        "Routing now. Don't make it ugly.",
    ],
    "success": [
        "Relax. I already fixed it.",
        "Handled. You're welcome.",
    ],
    "warning": [
        "We HAVE a plan. Don't sabotage it...",
        "Bad idea. Let's not do that.",
    ],
    "manual_test": [
        "Relay online. Voice check complete.",
        "Voice check complete. Still functional.",
    ],
}
DEFAULT_PLACEHOLDER_CATEGORY = "manual_test"


class RelayVoiceSpeakRequest(BaseModel):
    text: str | None = None
    category: str | None = None


def _checked_at() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _load_voice_config() -> tuple[dict[str, Any] | None, str | None]:
    if not VOICE_CONFIG_PATH.is_file():
        return None, f"Relay voice profile config not found: {VOICE_CONFIG_PATH}"

    try:
        config = json.loads(VOICE_CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return None, f"Relay voice profile config could not be loaded: {exc}"

    return config, None


def _relay_profile(config: dict[str, Any]) -> dict[str, Any]:
    profile = next(
        (item for item in config.get("voices", []) if item.get("id") == "smartmouth_relay"),
        {},
    )

    active_voice = str(config.get("active_tts_voice") or "af_bella")
    active_mode = str(config.get("active_tts_mode") or "sarcastic")
    active_style = str(config.get("active_placeholder_style") or "sarcastic_polish_04")
    secondary_style = str(config.get("secondary_placeholder_style") or "sarcastic_polish_03")
    backup_style = str(config.get("backup_placeholder_style") or "sarcastic_polish_02")

    return {
        "relay_name": str(profile.get("display_name") or "Smartmouth Relay"),
        "public_label": str(profile.get("public_label") or "Relay Companion"),
        "alternate_public_label": str(profile.get("alternate_public_label") or "Relay Voice"),
        "active_voice": active_voice,
        "active_mode": active_mode,
        "active_placeholder_style": active_style,
        "secondary_placeholder_style": secondary_style,
        "backup_placeholder_style": backup_style,
        "default_placeholder_text": PLACEHOLDER_LINES.get(active_style, PLACEHOLDER_LINES["sarcastic_polish_04"]),
        "secondary_placeholder_text": PLACEHOLDER_LINES.get(secondary_style, PLACEHOLDER_LINES["sarcastic_polish_03"]),
        "backup_placeholder_text": PLACEHOLDER_LINES.get(backup_style, PLACEHOLDER_LINES["sarcastic_polish_02"]),
        "available_placeholder_categories": list(PLACEHOLDER_CATEGORY_LINES.keys()),
        "default_placeholder_category": DEFAULT_PLACEHOLDER_CATEGORY,
        "placeholder_category_lines": {
            category: lines[0] for category, lines in PLACEHOLDER_CATEGORY_LINES.items()
        },
        "placeholder_category_variants": PLACEHOLDER_CATEGORY_LINES,
        "manual_only": True,
        "autoplay": False,
        "microphone": False,
        "openclaw": "unchanged",
        "checked_at": _checked_at(),
        "warning": None,
    }


def _kokoro_backend():
    import openjarvis.speech  # noqa: F401
    from openjarvis.core.registry import TTSRegistry

    if not TTSRegistry.contains("kokoro"):
        return None

    backend_cls = TTSRegistry.get("kokoro")
    return backend_cls()


def _resolve_placeholder_category(category: str | None) -> str:
    selected = (category or DEFAULT_PLACEHOLDER_CATEGORY).strip().lower()
    if selected not in PLACEHOLDER_CATEGORY_LINES:
        return DEFAULT_PLACEHOLDER_CATEGORY
    return selected


def _resolve_placeholder_text(text: str | None, category: str | None, profile: dict[str, Any]) -> tuple[str, str]:
    if text is not None and text.strip():
        return text.strip(), _resolve_placeholder_category(category)

    selected_category = _resolve_placeholder_category(category)
    category_lines = PLACEHOLDER_CATEGORY_LINES.get(selected_category)
    if not category_lines:
        return profile["default_placeholder_text"], selected_category
    return random.choice(category_lines), selected_category


@router.get("/config")
async def relay_voice_config() -> dict[str, Any]:
    """Return the locked placeholder voice pack configuration."""
    config, warning = _load_voice_config()
    if config is None:
        return {
            "relay_name": "Smartmouth Relay",
            "public_label": "Relay Companion",
            "alternate_public_label": "Relay Voice",
            "active_voice": "af_bella",
            "active_mode": "sarcastic",
            "active_placeholder_style": "sarcastic_polish_04",
            "secondary_placeholder_style": "sarcastic_polish_03",
            "backup_placeholder_style": "sarcastic_polish_02",
            "default_placeholder_text": PLACEHOLDER_LINES["sarcastic_polish_04"],
            "secondary_placeholder_text": PLACEHOLDER_LINES["sarcastic_polish_03"],
            "backup_placeholder_text": PLACEHOLDER_LINES["sarcastic_polish_02"],
            "available_placeholder_categories": list(PLACEHOLDER_CATEGORY_LINES.keys()),
            "default_placeholder_category": DEFAULT_PLACEHOLDER_CATEGORY,
            "placeholder_category_lines": {
                category: lines[0] for category, lines in PLACEHOLDER_CATEGORY_LINES.items()
            },
            "placeholder_category_variants": PLACEHOLDER_CATEGORY_LINES,
            "manual_only": True,
            "autoplay": False,
            "microphone": False,
            "openclaw": "unchanged",
            "checked_at": _checked_at(),
            "warning": warning,
            "synthesis_available": False,
            "backend": None,
        }

    response = _relay_profile(config)
    backend = _kokoro_backend()
    if backend is None:
        response["synthesis_available"] = False
        response["backend"] = None
        response["warning"] = "Kokoro TTS backend is not available."
        return response

    try:
        response["synthesis_available"] = bool(backend.health())
        response["backend"] = backend.backend_id
        if not response["synthesis_available"]:
            response["warning"] = "Kokoro TTS backend is not ready."
    except Exception as exc:
        response["synthesis_available"] = False
        response["backend"] = "kokoro"
        response["warning"] = f"Kokoro TTS backend health check failed: {exc}"

    return response


@router.post("/play")
async def relay_voice_play(req: RelayVoiceSpeakRequest) -> Response:
    """Manually synthesize the locked placeholder Relay line as WAV audio."""
    config, warning = _load_voice_config()
    if config is None:
        raise HTTPException(status_code=503, detail=warning or "Relay voice profile config is unavailable.")

    backend = _kokoro_backend()
    if backend is None:
        raise HTTPException(status_code=503, detail="Kokoro TTS backend is not available.")

    try:
        profile = _relay_profile(config)
        text, selected_category = _resolve_placeholder_text(req.text, req.category, profile)
        result = backend.synthesize(
            text,
            voice_id=profile["active_voice"],
            speed=1.0,
            output_format="wav",
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Relay placeholder voice synthesis failed: {exc}") from exc

    return Response(
        content=result.audio,
        media_type="audio/wav",
        headers={
            "Cache-Control": "no-store",
            "Content-Disposition": 'inline; filename="relay_placeholder_voice.wav"',
            "X-Relay-Placeholder-Voice": profile["active_voice"],
            "X-Relay-Placeholder-Mode": profile["active_mode"],
            "X-Relay-Placeholder-Style": profile["active_placeholder_style"],
            "X-Relay-Placeholder-Category": selected_category,
        },
    )


__all__ = ["router"]
