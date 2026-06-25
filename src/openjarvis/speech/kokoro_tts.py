"""Kokoro TTS backend — fully open-source, runs locally.

Requires the kokoro package: pip install kokoro
Falls back gracefully if not installed.
"""

from __future__ import annotations

import io
import sys
import wave
from pathlib import Path
from typing import List

from openjarvis.core.registry import TTSRegistry
from openjarvis.speech.tts import TTSBackend, TTSResult


@TTSRegistry.register("kokoro")
class KokoroTTSBackend(TTSBackend):
    """Kokoro TTS — local open-source voice synthesis."""

    backend_id = "kokoro"

    def __init__(self, *, model_path: str = "", device: str = "auto") -> None:
        self._model_path = model_path
        self._device = device
        self._pipeline = None

    @staticmethod
    def _repo_local_site_packages() -> Path:
        return (
            Path(__file__).resolve().parents[3]
            / "tools"
            / "kokoro.venv"
            / "Lib"
            / "site-packages"
        )

    def _import_kpipeline(self):
        try:
            from kokoro import KPipeline

            return KPipeline
        except ImportError:
            site_packages = self._repo_local_site_packages()
            if site_packages.is_dir():
                site_packages_str = str(site_packages)
                if site_packages_str not in sys.path:
                    sys.path.insert(0, site_packages_str)
                try:
                    from kokoro import KPipeline

                    return KPipeline
                except ImportError:
                    pass
            raise RuntimeError(
                "kokoro package not installed in the Relay runtime. "
                "Expected the repo-local sandbox at tools\\kokoro.venv or an active server environment with kokoro available."
            )

    def _ensure_pipeline(self) -> None:
        if self._pipeline is not None:
            return
        KPipeline = self._import_kpipeline()
        self._pipeline = KPipeline(lang_code="a")

    @staticmethod
    def _chunk_to_samples(audio) -> List[float]:
        if hasattr(audio, "tolist"):
            audio = audio.tolist()
        if isinstance(audio, (list, tuple)):
            return [float(sample) for sample in audio]
        return [float(audio)]

    @staticmethod
    def _write_wav(samples: List[float], sample_rate: int) -> bytes:
        pcm = bytearray()
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample))
            pcm.extend(int(clamped * 32767.0).to_bytes(2, byteorder="little", signed=True))

        buf = io.BytesIO()
        with wave.open(buf, "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(bytes(pcm))
        return buf.getvalue()

    def synthesize(
        self,
        text: str,
        *,
        voice_id: str = "af_heart",
        speed: float = 1.0,
        output_format: str = "wav",
    ) -> TTSResult:
        self._ensure_pipeline()

        samples: List[float] = []
        for _, _, audio in self._pipeline(text, voice=voice_id, speed=speed):
            samples.extend(self._chunk_to_samples(audio))

        if not samples:
            return TTSResult(audio=b"", format=output_format, voice_id=voice_id)

        if output_format.lower() != "wav":
            raise RuntimeError("Kokoro Relay backend currently supports wav output only.")
        audio_bytes = self._write_wav(samples, 24000)

        return TTSResult(
            audio=audio_bytes,
            format=output_format,
            voice_id=voice_id,
            sample_rate=24000,
            duration_seconds=len(samples) / 24000,
            metadata={"backend": "kokoro"},
        )

    def available_voices(self) -> List[str]:
        return ["af_heart", "af_bella", "am_adam", "am_michael"]

    def health(self) -> bool:
        try:
            self._ensure_pipeline()
            return True
        except RuntimeError:
            return False
