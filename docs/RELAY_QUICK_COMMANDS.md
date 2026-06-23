# Relay Quick Commands

Run these commands from `D:\AI\TRIPPIN_AI_RELAY`.

## Start the full stack

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_relay_stack.ps1
```

## Run one service

Backend only:

```powershell
uv run relay serve
```

Frontend only:

```powershell
npm --prefix .\frontend run dev
```

## Build and checks

```powershell
npm --prefix .\frontend run build
git status --short
git --no-pager log --oneline -8
uv run relay doctor
```

## OpenClaw bridge check

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_openclaw_bridge.ps1
```

## Relay agent roster

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_AGENT_ROSTER.md
```

## Relay current state

Source-of-truth handoff summary:

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_CURRENT_STATE.md
```

## Relay TTS plan

Planning reference only:

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_TTS_PLAN.md
D:\AI\TRIPPIN_AI_RELAY\config\relay_voice_profiles.json
```

Read-only local feasibility check:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_relay_tts_feasibility.ps1
```

Piper setup check:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_setup.ps1
```

Piper voice model selection:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\download_piper_voice_model_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\download_piper_voice_model_gated.ps1 -AllowDownload
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_PIPER_VOICE_MODEL_SELECTION.md
D:\AI\TRIPPIN_AI_RELAY\config\piper_voice_models.json
```

Piper first test WAV:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1 -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1 -AllowGenerate -Line "Relay online. Try not to break anything expensive."
```

Piper sandbox prep:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\prepare_piper_sandbox.ps1
```

Gated Piper dry runs:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_python_runtime.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\install_piper_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1
```

Manual approval required:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\install_piper_gated.ps1 -AllowInstall
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1 -AllowGenerate
```

`-AllowInstall` was a no-install/manual-review placeholder in v2.1. `-AllowGenerate` does not download models or play audio.

As of v2.2, `-AllowInstall` creates only `tools\piper.venv` with Python 3.11 and installs pinned `piper-tts` there. It does not download a voice model or generate audio.

Piper audio review notes:

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_PIPER_AUDIO_REVIEW.md
```

Piper voice comparison:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_voice_comparison_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_voice_comparison_gated.ps1 -AllowDownload -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_voice_comparison_gated.ps1 -AllowDownload -AllowGenerate -Line "Routing that now. Shocking development: we are using a plan."
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_PIPER_VOICE_COMPARISON.md
```

> Do not run `jarvis self-update` on the Trippin AI Relay fork.
