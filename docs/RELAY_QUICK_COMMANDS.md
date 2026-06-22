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

> Do not run `jarvis self-update` on the Trippin AI Relay fork.
