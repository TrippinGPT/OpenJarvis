# Relay Kokoro First WAV Test

## Purpose

This document defines the first gated local Kokoro WAV test lane for Relay. It is a controlled local test only. It does not add runtime TTS, autoplay, microphone access, or voice cloning.

## Current status

- Kokoro is installed locally in `tools\kokoro.venv`
- The first WAV test has been run locally and is the baseline for the comparison sweep
- The local cache lives under `tools\kokoro\models`
- Output WAV files are ignored by Git

## Generated result

- `D:\AI\TRIPPIN_AI_RELAY\outputs\tts_tests\relay_kokoro_first_20260623_161539.wav`

## Test voice and line

- Baseline voice: `af_heart`
- Language: American English (`a`)
- Planned first line source: `config\relay_voice_profiles.json`
- Default line: `Relay online. Try not to break anything expensive.`

This is a technical baseline only. It is not a final Relay voice decision.

The next local review lane is the gated Kokoro voice/style comparison sweep in `docs/RELAY_KOKORO_VOICE_SWEEP.md`.

## Output naming

The first test WAV uses a timestamped local filename under `outputs\tts_tests`:

```text
relay_kokoro_first_<YYYYMMDD_HHMMSS>.wav
```

## Commands

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1
```

Prefetch only:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1 -AllowModelDownload
```

Generate the first WAV:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1 -AllowModelDownload -AllowGenerate
```

## Safety rules

- Do not generate audio unless the explicit generation gate is passed.
- Do not autoplay the WAV.
- Do not add app/runtime TTS.
- Do not access the microphone.
- Do not clone real people, actors, or copyrighted characters.
- Do not modify OpenClaw.

## Next step

After the first WAV exists, the next work is the gated voice/style comparison sweep and review only. App integration remains blocked until a later approved milestone.
