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

> Do not run `jarvis self-update` on the Trippin AI Relay fork.
