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

- `neutral` - clean split only.
- `dry` - slightly sarcastic delivery.
- `sarcastic` - stronger attitude, still readable.
- `command` - short directive phrasing.

The formatter trims filler words when possible and breaks long lines into short spoken segments.
Each output line is structured with:

- `Text`
- `PauseAfter` (`none`, `short`, `medium`, `long`)
- `Emphasis` (`none`, `slight`, `caps`)

The runner converts those fields into timing-friendly speech text before Kokoro synthesis.

## Example

Input:

```text
Routing that now. Shocking development: we are using a plan.
```

Expected delivery examples:

- `neutral`
  - `Routing now.` `PauseAfter=short`
  - `Shocking development.` `PauseAfter=short`
  - `We are using a plan.` `PauseAfter=medium`
- `dry`
  - `Routing now.` `PauseAfter=short`
  - `We actually have a plan.` `PauseAfter=medium` `Emphasis=slight`
- `sarcastic`
  - `Routing now.` `PauseAfter=short`
  - `We HAVE a plan.` `PauseAfter=none` `Emphasis=caps`
  - `Try not to ruin it.` `PauseAfter=medium`
- `command`
  - `Routing now.` `PauseAfter=short`
  - `Stay on task.` `PauseAfter=none` `Emphasis=slight`

## Cadence and timing

The runner renders pauses into speech text as:

- `short` -> `.`
- `medium` -> `...`
- `long` -> `... ...`

This keeps the delivery short and punchy while still giving the voice room to breathe.

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
- `sarcastic` is the active polish mode.
- The placeholder pack is now locked with `sarcastic_polish_04` as the default style.
- `sarcastic_polish_03` is the secondary style.
- `sarcastic_polish_02` is the backup style.
- The formatter and gated runner are local-only utilities.
- Runtime/app TTS is still not enabled.
- The cadence layer adds pause and emphasis metadata for better delivery timing.
- The sarcastic-only polish lane is the current quality target.
