# Relay Piper Voice Model Selection

## Purpose

This document defines the approved local Piper voice-model selection lane for Trippin AI Relay. It is a model gate only: no audio generation, no autoplay, no runtime TTS integration, and no microphone or audio-capture behavior.

## Current status

- Voice-model candidate selected for local testing
- Model files remain local under `tools\piper\voices`
- Voice-model metadata lives in `config\piper_voice_models.json`
- No audio has been generated yet
- No Popout voice integration exists yet
- No microphone or audio capture is used
- No voice cloning is allowed
- Piper requires both the `.onnx` model file and the matching `.onnx.json` config file

## Approved candidate

- `en_US_lessac_medium`
- Display name: English US Lessac Medium
- Language: `en_US`
- Quality: medium
- Status: `approved_for_local_test`
- License review status: `needs_review_before_distribution`

## Safety rules

- Use an original Relay voice only.
- Do not clone or impersonate real people.
- Do not clone or impersonate copyrighted characters.
- Do not enable autoplay.
- Do not use microphone or audio capture.
- Do not place voice-model files inside `tools\piper.venv`.
- Keep voice-model metadata in `config\piper_voice_models.json`.
- Keep downloaded voice files ignored by Git.

## Why this candidate

- It is a straightforward local/offline voice-model lane.
- It keeps the first test focused on a single reviewed candidate.
- It stays separate from Relay runtime TTS integration.
- It gives a clear path to a future controlled test line without adding a browser-executed action path.

## File layout

```text
config\piper_voice_models.json
tools\piper\voices\en_US-lessac-medium.onnx
tools\piper\voices\en_US-lessac-medium.onnx.json
```

## Later milestone

A future approved milestone may use the downloaded voice pair for one controlled local test line. That later step still must not add autoplay, microphone access, voice cloning, or Popout runtime integration without explicit approval.

## Git boundary

Downloaded voice files remain local-only and ignored by Git. Only the config and scripts belong in the repository.
