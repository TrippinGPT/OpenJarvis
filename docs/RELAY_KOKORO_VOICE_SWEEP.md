# Relay Kokoro Voice/Style Sweep

## Purpose

This document defines the gated Kokoro voice/style comparison lane for Relay. It stays local-only and planning-safe. It does not add runtime TTS, autoplay, microphone access, voice cloning, or browser shell execution.

## Current status

- Kokoro is installed locally in `tools\kokoro.venv`
- The first Kokoro WAV has already been generated locally and serves as the baseline
- The sweep lane compares several official Kokoro voices against several Smartmouth Relay lines
- Output WAV files are ignored by Git

## Baseline and sweep set

Baseline voice:

- `af_heart`

Default comparison voices (American English):

- `af_heart`
- `af_bella`
- `af_nova`
- `am_michael`

Comparison lines:

- The first three Smartmouth Relay planning lines from `config\relay_voice_profiles.json`

Those lines are:

1. `Relay online. Try not to break anything expensive.`
2. `Routing that now. Shocking development: we are using a plan.`
3. `I can make this faster, cleaner, and less cursed.`

## Python selection

The sweep runner defaults to:

```text
D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe
```

If you need to be explicit, pass `-PythonExe` with that exact path. The runner validates that interpreter directly, not the default system Python.

## Output naming

The sweep writes one WAV per voice/line combination under `outputs\tts_tests`:

```text
relay_kokoro_sweep_<voice>_line<NN>_<YYYYMMDD_HHMMSS>.wav
```

## Commands

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1
```

Dry run with explicit venv Python:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -PythonExe D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe
```

Prefetch only:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload
```

Generate the sweep WAVs:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload -AllowGenerate
```

Generate the sweep WAVs with explicit venv Python:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload -AllowGenerate -PythonExe D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe
```

## Safety rules

- Do not generate audio unless the explicit generation gate is passed.
- Do not autoplay the WAVs.
- Do not add app/runtime TTS.
- Do not access the microphone.
- Do not clone real people, actors, or copyrighted characters.
- Do not modify OpenClaw.

## Next step

After the sweep is recorded, the next work is review only. App integration remains blocked until a later approved milestone.
