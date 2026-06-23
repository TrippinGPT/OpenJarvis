# Relay Kokoro Prerequisites

## Purpose

This document prepares for a future Kokoro local setup without installing Kokoro yet. It is a prerequisite-readiness lane only.

## Current blocker summary

- Default Python is 3.14.5
- Python 3.11 is not detected
- `espeak-ng` is not found on PATH
- `tools\kokoro` does not exist
- `tools\kokoro.venv` does not exist
- Kokoro is not installed

## Recommended target

- Use isolated Python 3.11 for Kokoro
- Do not rely on default Python 3.14
- Keep Kokoro isolated under `tools\kokoro` and `tools\kokoro.venv`

## Prerequisite checklist

- Python 3.11 is installed and discoverable
- uv is available
- `espeak-ng` is installed and discoverable on PATH
- `outputs\tts_tests` exists
- Git ignore rules protect model and audio outputs

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
