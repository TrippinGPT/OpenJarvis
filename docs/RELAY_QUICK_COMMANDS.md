# Relay Quick Commands

Run these commands from `D:\AI\TRIPPIN_AI_RELAY`.

## Start the full stack

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start_relay_stack.ps1
```

Stop the Relay stack:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop_relay_stack.ps1
```

Restart the Relay stack:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\restart_relay_stack.ps1
```

Stop or restart Relay-owned Ollama too, only when you explicitly want that:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop_relay_stack.ps1 -IncludeOllama
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\restart_relay_stack.ps1 -IncludeOllama
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

Relay voice milestone summary:

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_VOICE_MILESTONE_SUMMARY.md
```

Locked placeholder voice pack:

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_SARCASTIC_POLISH.md
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

Kokoro feasibility check:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_kokoro_feasibility.ps1
```

Kokoro prerequisite check:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_kokoro_prereqs.ps1
```

Kokoro gated venv setup:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\setup_kokoro_venv_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\setup_kokoro_venv_gated.ps1 -AllowSetup
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\setup_kokoro_venv_gated.ps1 -AllowSetup -SkipPackageInstall
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_KOKORO_TTS_PLAN.md
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_KOKORO_PREREQUISITES.md
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_KOKORO_VENV_SETUP.md
```

Kokoro first WAV test:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1 -AllowModelDownload
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1 -AllowModelDownload -AllowGenerate
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_KOKORO_FIRST_WAV_TEST.md
```

Kokoro voice/style comparison sweep:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload -AllowGenerate
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_KOKORO_VOICE_SWEEP.md
```

Smartmouth delivery pack:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\format_smartmouth_lines.ps1 -Line "Routing that now. Shocking development: we are using a plan." -Mode sarcastic
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_smartmouth_test_gated.ps1 -Line "Routing that now. Shocking development: we are using a plan."
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_smartmouth_test_gated.ps1 -Line "Routing that now. Shocking development: we are using a plan." -Mode sarcastic -AllowGenerate
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_SMARTMOUTH_DELIVERY.md
```

Sarcastic polish lane:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_sarcastic_polish_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_sarcastic_polish_gated.ps1 -AllowGenerate
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_SARCASTIC_POLISH.md
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

Amy tuning:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_amy_tuning_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_amy_tuning_gated.ps1 -AllowGenerate -UseDefaultLineSet
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_amy_tuning_gated.ps1 -AllowGenerate -Line "Routing that now. Shocking development: we are using a plan."
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_PIPER_AMY_TUNING.md
```

Danny candidate test:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_danny_test_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_danny_test_gated.ps1 -AllowDownload -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_danny_test_gated.ps1 -AllowDownload -AllowGenerate -LengthScales 0.9,0.85
```

```text
D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_PIPER_DANNY_TEST.md
```

> Do not run `jarvis self-update` on the Trippin AI Relay fork.
