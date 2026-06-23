# Relay Kokoro Prerequisites

## Purpose

This document prepares for a future Kokoro local setup without installing Kokoro yet. It is a prerequisite-readiness lane only.

## Current blocker summary

- Default Python is 3.14.5
- `py -3.11` does not resolve on this machine
- `py -0p` lists an Astral/CPython 3.11.15 uv-managed runtime
- uv-managed CPython 3.11.15 is present and should be used for a future Kokoro setup
- `espeak-ng` is not found on PATH
- `tools\kokoro` does not exist
- `tools\kokoro.venv` does not exist
- Kokoro is not installed

## Recommended target

- Use isolated uv-managed Python 3.11.15 for Kokoro
- Do not rely on default Python 3.14
- Keep Kokoro isolated under `tools\kokoro` and `tools\kokoro.venv`

## Prerequisite checklist

- Python 3.11 is installed and discoverable through `py -3.11` or the uv-managed CPython runtime
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
