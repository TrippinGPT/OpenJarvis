# Relay Kokoro TTS Plan

## Purpose

Kokoro 82M is the next local TTS lane to evaluate after the Piper voice-fit failures. This document is planning-only. It does not authorize installation, model download, audio generation, autoplay, microphone access, or runtime integration.

## Why Kokoro

- Open-weight 82M TTS model
- Apache-licensed weights according to the official model page
- Potentially more natural than the Piper voices already tested
- Still a local/offline candidate after initial setup

## Official sources

- GitHub: https://github.com/hexgrad/kokoro
- Hugging Face: https://huggingface.co/hexgrad/Kokoro-82M

## Current status

- Feasibility only
- No Kokoro install yet
- No Kokoro model download yet
- No audio generated
- No app/runtime TTS
- No autoplay
- No microphone or audio capture

### v2.5.1 prerequisite lane

- Python 3.11 is the preferred target for a future Kokoro setup.
- The machine currently defaults to Python 3.14.5, so default Python is not the install target.
- `espeak-ng` is missing on PATH and must be resolved before a future install task.
- The Kokoro prerequisite checklist lives in `docs/RELAY_KOKORO_PREREQUISITES.md`.
- The read-only prerequisite checker is `scripts/check_kokoro_prereqs.ps1`.

## Safety

- Use an original Relay voice only
- Do not clone real people, actors, or copyrighted characters
- Do not impersonate a recognizable voice
- Do not add voice cloning
- Do not bypass existing safety boundaries
- Do not add runtime speech until a future task explicitly approves it

## Local target

- Future isolated folder: `tools\kokoro`
- Future local venv: `tools\kokoro.venv`
- Future output folder may reuse: `outputs\tts_tests`

## Risks and questions to answer later

- Windows compatibility
- Python version compatibility
- Python package dependencies
- `espeak-ng` requirement
- CPU/GPU performance on the OMEN laptop
- License review before any distribution discussion
- Voice quality and persona fit still need local WAV review

## Recommended next checks

- Run `scripts/check_kokoro_prereqs.ps1`
- Run `scripts/check_kokoro_feasibility.ps1`
- Review official Kokoro package and model documentation
- Keep the lane planning-only until a later approved install task

No command in this document authorizes installation, download, generation, playback, or application integration.

## Related files

- `docs/RELAY_KOKORO_PREREQUISITES.md`
- `scripts/check_kokoro_prereqs.ps1`
- `scripts/check_kokoro_feasibility.ps1`
