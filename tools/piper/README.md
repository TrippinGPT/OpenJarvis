# Relay Piper Sandbox

## Purpose

This directory is the local sandbox location reserved for a future approved Piper prototype.

## Current status

- Empty planning folder
- Piper is not installed
- No Piper binary or voice model has been downloaded
- No TTS runtime or audio generation is configured

A future explicitly approved setup may place reviewed Piper binaries and local configuration notes here.

The maintained candidate lane is `piper-tts` from [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl). v2.1 adds gated scripts, but no package or model is installed.

Expected future local layout:

```text
tools\piper\.venv
tools\piper\models
```

`scripts\install_piper_gated.ps1` defaults to dry-run and keeps `-AllowInstall` as a manual-only placeholder. Do not manually populate this directory without reviewing source, version, license, and compatibility.

## Boundaries

- Do not commit large binaries or downloaded voice-model files without explicit review.
- Review source, version, license, and checksums before adding future tools or models.
- Do not clone or imitate a real person.
- Do not impersonate a copyrighted character.
- The Relay voice must remain original.
- Do not add microphone or audio-capture behavior.
- Do not modify OpenClaw from this sandbox.
