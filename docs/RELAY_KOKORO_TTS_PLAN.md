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
- Prerequisites are now satisfied and the gated venv setup lane is complete

### v2.5.1 prerequisite lane

- Python 3.11 is the preferred target for a future Kokoro setup.
- The machine currently defaults to Python 3.14.5, so default Python is not the install target.
- `py -0p` also lists a uv-managed Astral CPython 3.11.15 runtime, which is the intended local target.
- `espeak-ng` is installed and ready for the gated setup lane.
- The Kokoro prerequisite checklist lives in `docs/RELAY_KOKORO_PREREQUISITES.md`.
- The read-only prerequisite checker is `scripts/check_kokoro_prereqs.ps1`.

### v2.5.2 gated venv setup lane

- The gated Kokoro venv setup lane is complete.
- `scripts/setup_kokoro_venv_gated.ps1` is dry-run by default.
- `-AllowSetup` is required to create `tools\kokoro.venv`.
- `-SkipPackageInstall` allows a venv-only setup with pip upgrade only.
- No audio generation happens in this milestone.
- The setup doc is `docs/RELAY_KOKORO_VENV_SETUP.md`.

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
- `scripts/setup_kokoro_venv_gated.ps1`
- [Relay Kokoro Venv Setup](RELAY_KOKORO_VENV_SETUP.md)
- `scripts/check_kokoro_feasibility.ps1`
