# Relay TTS Test Outputs

## Purpose

This directory is reserved for future local Relay TTS test output.

## Current status

- No audio has been generated.
- No voice samples are stored here.
- No playback or application integration is configured.
- Generated WAV files in this folder are local test artifacts.
- Generated WAV and MP3 files are ignored by Git.
- Do not commit generated audio without explicit review.

Future explicitly approved tests may save temporary Relay voice samples here.

`scripts\run_piper_test_line_gated.ps1` defaults to dry-run. Generation requires `-AllowGenerate`, a Relay-local Piper module, and one manually supplied reviewed voice model. The script does not download models or auto-play output.

Comparison WAV naming convention:

- `relay_compare_<voiceid>_<YYYYMMDD_HHMMSS>.wav`
- One file per selected voice when the comparison lane is run with `-AllowGenerate`
- Comparison WAVs remain ignored by Git

Amy tuning WAV naming convention:

- `relay_amy_tune_<NN>_<YYYYMMDD_HHMMSS>.wav`
- One file per line when Amy tuning is run with `-AllowGenerate`
- Amy tuning WAVs remain ignored by Git

## Boundaries

- Do not commit generated audio unless explicitly approved.
- Do not store private, sensitive, or third-party audio.
- Do not store cloned voices or impersonations.
- Use only an original Relay voice.
- The first approved test line should come from `config/relay_voice_profiles.json` or `docs/RELAY_SCRIPT_PACK.md`.
- Do not auto-play generated output unless explicitly approved.
