# Relay Smartmouth Delivery Pack

This document defines the local delivery layer for Relay lines before any future runtime TTS integration.

## Purpose

- Convert Relay text into short, TTS-friendly lines.
- Keep the tone compact, punchy, and original.
- Support local-only Kokoro testing with `af_bella`.

## Safety boundaries

- No autoplay.
- No microphone or audio capture.
- No app/runtime TTS integration.
- No OpenClaw changes.
- No model downloads as part of the delivery layer.
- No voice switching.
- No cloning or impersonating real people or copyrighted characters.

## Formatter modes

`scripts/format_smartmouth_lines.ps1` supports:

- `neutral` — clean split only.
- `dry` — slightly sarcastic delivery.
- `sarcastic` — stronger attitude, still readable.
- `command` — short directive phrasing.

It trims filler words when possible and breaks long lines into short spoken segments.

## Example

Input:

```text
Routing that now. Shocking development: we are using a plan.
```

Expected delivery examples:

- `neutral`
  - `Routing now.`
  - `Shocking development.`
  - `We are using a plan.`
- `dry`
  - `Routing now.`
  - `We actually have a plan.`
- `sarcastic`
  - `Routing now.`
  - `We have a plan.`
  - `Try not to ruin it.`
- `command`
  - `Routing now.`
  - `Stay on task.`

## Kokoro test runner

Use the gated local runner:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_smartmouth_test_gated.ps1 -Line "Routing that now. Shocking development: we are using a plan."
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_smartmouth_test_gated.ps1 -Line "Routing that now. Shocking development: we are using a plan." -Mode sarcastic -AllowGenerate
```

The runner uses the local Kokoro venv at:

```text
D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe
```

The output WAV is written under `outputs\tts_tests` and remains ignored by Git.

## Current status

- `af_bella` is the current Smartmouth delivery voice.
- The formatter and gated runner are local-only utilities.
- Runtime/app TTS is still not enabled.
