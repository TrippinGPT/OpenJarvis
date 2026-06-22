# Relay TTS Test Outputs

## Purpose

This directory is reserved for future local Relay TTS test output.

## Current status

- No audio has been generated.
- No voice samples are stored here.
- No playback or application integration is configured.

Future explicitly approved tests may save temporary Relay voice samples here.

`scripts\run_piper_test_line_gated.ps1` defaults to dry-run. Generation requires `-AllowGenerate`, a Relay-local Piper module, and one manually supplied reviewed voice model. The script does not download models or auto-play output.

## Boundaries

- Do not commit generated audio unless explicitly approved.
- Do not store private, sensitive, or third-party audio.
- Do not store cloned voices or impersonations.
- Use only an original Relay voice.
- The first approved test line should come from `config/relay_voice_profiles.json` or `docs/RELAY_SCRIPT_PACK.md`.
- Do not auto-play generated output unless explicitly approved.
