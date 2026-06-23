# Relay Kokoro Venv Setup

## Purpose

This document defines the gated setup lane for an isolated Kokoro Python environment. It is a setup-only milestone, not a runtime TTS integration.

## Current prerequisite status

- Python 3.11 is available through the verified uv-managed CPython 3.11.15 runtime
- `espeak-ng` is installed and available
- Default Python 3.14 should not be used for Kokoro
- The next gated lane after setup is the first Kokoro WAV test

## Setup boundary

- Dry-run by default
- `-AllowSetup` is required to create the venv or install the Kokoro package
- `-SkipPackageInstall` creates the venv and upgrades pip only
- No audio generation in this milestone
- No app integration
- No voice cloning
- No microphone or audio capture

## Target paths

```text
D:\AI\TRIPPIN_AI_RELAY\tools\kokoro
D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv
```

Future Kokoro model/cache paths remain ignored by Git. Do not place downloaded weights or generated audio inside the venv.

## Commands

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\setup_kokoro_venv_gated.ps1
```

Approved setup:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\setup_kokoro_venv_gated.ps1 -AllowSetup
```

Venv-only setup:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\setup_kokoro_venv_gated.ps1 -AllowSetup -SkipPackageInstall
```

## Manual setup note

Manual setup happens only after explicit approval. The gated script must remain dry-run by default and must not download Kokoro model weights or generate audio.

After the venv exists, the first gated WAV test is handled by `scripts/run_kokoro_first_wav_gated.ps1`.
