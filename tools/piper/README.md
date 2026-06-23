# Relay Piper Sandbox

## Purpose

This directory is the local sandbox location reserved for a future approved Piper prototype.

## Current status

- Piper runtime support folder
- `piper-tts` 1.4.2 is installed in the sibling `tools\piper.venv`
- No standalone Piper bundle or voice model has been downloaded
- No TTS runtime or audio generation is configured

A future explicitly approved setup may place reviewed Piper binaries and local configuration notes here.

The maintained candidate lane is `piper-tts` from [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl). v2.1 adds gated scripts, but no package or model is installed.

Local layout:

```text
tools\piper.venv
tools\piper\models
```

`scripts\install_piper_gated.ps1` defaults to dry-run. With explicit `-AllowInstall`, v2.2 creates `tools\piper.venv` with Python 3.11 and installs the reviewed `piper-tts` package there only.

- Do not commit `tools\piper.venv`.
- Do not copy packages into system Python or global site packages.
- Do not commit downloaded model files without review.
- Model selection/download and audio generation remain separate approval-gated steps.

## Boundaries

- Do not commit large binaries or downloaded voice-model files without explicit review.
- Review source, version, license, and checksums before adding future tools or models.
- Do not clone or imitate a real person.
- Do not impersonate a copyrighted character.
- The Relay voice must remain original.
- Do not add microphone or audio-capture behavior.
- Do not modify OpenClaw from this sandbox.
