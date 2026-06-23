# Relay Kokoro Prerequisites

## Purpose

This document prepares for a future Kokoro local setup without installing Kokoro yet. It is a prerequisite-readiness lane only.

## Current readiness summary

- Default Python is 3.14.5, but Kokoro does not target it
- `py -3.11` still does not resolve on this machine
- `py -0p` lists an Astral/CPython 3.11.15 uv-managed runtime
- uv-managed CPython 3.11.15 is present and should be used for Kokoro
- `espeak-ng` is installed and available at `C:\Program Files\eSpeak NG\espeak-ng.exe`
- `tools\kokoro` now exists as the Relay Kokoro sandbox folder
- `tools\kokoro.venv` now exists after the gated setup lane
- Kokoro 0.9.4 is installed in `tools\kokoro.venv`
- `tools\kokoro\models` now exists as the local Kokoro cache
- The first gated Kokoro WAV exists under `outputs\tts_tests`

## Recommended target

- Use isolated uv-managed Python 3.11.15 for Kokoro
- Do not rely on default Python 3.14
- Keep Kokoro isolated under `tools\kokoro` and `tools\kokoro.venv`

## Prerequisite checklist

- Python 3.11 is available through the verified uv-managed CPython runtime
- uv is available
- `espeak-ng` is installed and discoverable on PATH or via `C:\Program Files\eSpeak NG\espeak-ng.exe`
- `outputs\tts_tests` exists
- Git ignore rules protect model and audio outputs

## Next step

- The prerequisites are ready and the gated Kokoro venv setup has already been completed.
- Run `scripts\setup_kokoro_venv_gated.ps1` without flags for a dry run if you need to review the plan again.
- Use `-AllowSetup -SkipPackageInstall` only for a venv-only refresh.
- The next gated lane is the first Kokoro WAV test in `docs/RELAY_KOKORO_FIRST_WAV_TEST.md`.

## Manual install notes

- Do not use automatic installer commands here unless they are clearly marked manual-review only.
- This document does not install anything.
- This document does not create folders, download models, or generate audio.

## Safety boundaries

- No install yet
- No model download yet
- No audio generation yet
- No app integration yet
- No voice cloning
- No real-person, actor, or copyrighted-character impersonation
