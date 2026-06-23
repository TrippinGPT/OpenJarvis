# Relay Current State

This document is the concise source of truth for the current Trippin AI Relay handoff state.

## 1. What Relay is

- Trippin AI Relay is the local cockpit and command-center fork.
- OpenClaw Core remains the engine and workflow repository at `D:\AI\OPENCLAW`.
- Relay and OpenClaw remain separate repositories.
- The current bridge exposes read-only status information; it does not merge or execute OpenClaw workflows.

## 2. How to start

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\start_relay_stack.ps1
```

The launcher starts:

- Backend: [http://127.0.0.1:8000/](http://127.0.0.1:8000/)
- Frontend: [http://localhost:5173/](http://localhost:5173/)

After startup commands are sent, the launcher automatically opens the frontend in the default browser.

## 3. Main routes

- Dashboard: `/dashboard`
- Agents: `/agents`
- Relay Popout: `/relay-popout`
- Get Started: `/get-started`
- Read-only OpenClaw bridge API: `/api/relay/openclaw-bridge/status`

## 4. Current model and default

- Default model: `relay-qwen:latest`
- Runtime: local Ollama model
- The default model loading and copy-format behavior was fixed in v1.4.1.

## 5. Current tags and milestones

- `relay-v0.4-local-command-center`
- `relay-v0.5-ui-cleanup-shortcut-docs`
- `relay-v0.6-dashboard-commands`
- `relay-v0.6.1-agent-layout-polish`
- `relay-v0.7-openclaw-bridge-manifest`
- `relay-v0.8-openclaw-status-dashboard`
- `relay-v0.9-openclaw-bridge-endpoint`
- `relay-v1.1.2-agent-route-preview`
- `relay-v1.1.3-clickable-agent-nodes`
- `relay-v1.1.4-dispatch-route-fix`
- `relay-v1.2-dashboard-agent-context`
- `relay-v1.3-agent-roster`
- `relay-v1.4-safe-agent-actions`
- `relay-v1.4.1-models-copy-format-fix`
- `relay-v1.5-popout-companion-window`
- `relay-v1.5.2-popout-hud-redesign`
- `relay-v1.5.3-popout-responsive-fullscreen`
- `relay-v1.6-personality-script-pack`
- `relay-v1.7-tts-planning`
- `relay-v1.8-tts-feasibility-checker`
- `relay-v1.9-piper-prototype-plan`
- `relay-v1.9.1-current-state-summary`
- `relay-v2.0-piper-sandbox-prep`
- `relay-v2.1-gated-piper-runner`
- `relay-v2.1.1-piper-python-runtime-check`
- `relay-v2.2-local-piper-install`
- `relay-v2.2.1-piper-venv-path-normalized`
- `relay-v2.3-piper-voice-model-gate`

## 6. Current features

- Branded Trippin AI Relay UI
- Dashboard command center
- Animated central agent mesh
- Manual active-mesh and agent route previews
- Clickable Dispatch, Recon, Patch, Redline, Racket, Hermes, and Veto nodes
- Dashboard-to-Agents selected context
- Safe Agent Actions for copy/reference workflows
- Read-only OpenClaw bridge manifest, checker, API endpoint, and dashboard status
- Relay Popout companion HUD
- Responsive fullscreen popout monitor mode
- Relay personality and script-pack documentation
- TTS feasibility plan and checker
- Piper prototype plan and read-only setup checker
- Piper-local sandbox folders with boundary README files and a constrained preparation script
- Dry-run-first gated Piper install and test-line scripts
- Read-only Piper Python runtime compatibility checker
- Isolated Python 3.11 Piper installation under `tools\piper.venv`
- Approved Piper voice-model gate with local files under `tools\piper\voices`

## 7. Safety boundaries

- No arbitrary shell execution from the browser.
- The OpenClaw bridge is read-only.
- Do not modify OpenClaw without explicit user approval.
- Do not run `jarvis self-update` on the Relay fork.
- Do not merge upstream without review.
- No real-money trading or financial execution.
- PaperForge is fake money only: no wallets, private keys, swaps, or real funds.
- Market and intelligence output is research/reporting only, not investment advice, predictions, or guaranteed outcomes.
- Any future Relay voice must be original. Do not clone or impersonate real people or copyrighted characters.

## 8. Current TTS status

- No TTS runtime or application integration exists.
- No audio has been generated.
- Piper is installed locally; Kokoro is not installed.
- The local TTS feasibility check passed for a planning-only prototype.
- The Piper prototype plan and read-only setup checker exist.
- v2.0 prepares only the Relay-local Piper and TTS-test sandbox folders.
- v2.1 adds gated scripts only. The install gate is a manual-review placeholder.
- v2.1.1 inventories local Python runtimes before installation. Python 3.11 is preferred and Python 3.12 is acceptable.
- This machine defaults to Python 3.14.5; the launcher also reports Python 3.12 and uv-managed CPython 3.11.15.
- v2.2 created `tools\piper.venv` with Python 3.11.15 and installed `piper-tts` 1.4.2 locally.
- v2.2.1 verified `tools\piper.venv` as the canonical active path; legacy `tools\piper\.venv` is absent and unused.
- v2.3 adds the approved local test voice `en_US_lessac_medium` and the gated download script.
- Voice-model files live only under `tools\piper\voices` and remain ignored by Git.
- No Piper package was installed globally.
- The selected voice-model pair lives under `tools\piper\voices` and no audio has been generated.
- No Relay Popout voice toggle or automatic speech exists.
- Model download, audio generation, playback, or UI voice controls require explicit user approval in a future task.

## 9. Next possible milestones

- **v2.3:** Approved Piper voice-model selection/download gate
- **v2.4:** One controlled local test-line generation
- **v2.5:** User-controlled Relay Popout voice toggle
- **v2.6:** Agent-specific original voice profiles
- **v2.7:** Real routing signals connected to agent mesh animation
- **v2.8:** Safe preflight actions

These are proposed milestones only. They do not authorize installation, downloads, audio generation, agent execution, or OpenClaw changes.

## 10. Useful commands

Run from `D:\AI\TRIPPIN_AI_RELAY`:

```powershell
git status --short
git --no-pager log --oneline -10
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_openclaw_bridge.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_relay_tts_feasibility.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_setup.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\download_piper_voice_model_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\download_piper_voice_model_gated.ps1 -AllowDownload
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\prepare_piper_sandbox.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_python_runtime.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\install_piper_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1
```

Related references:

- [Relay Quick Commands](RELAY_QUICK_COMMANDS.md)
- [Relay OpenClaw Integration Plan](RELAY_OPENCLAW_INTEGRATION_PLAN.md)
- [Relay Agent Roster](RELAY_AGENT_ROSTER.md)
- [Relay TTS Plan](RELAY_TTS_PLAN.md)
- [Relay Piper Prototype Plan](RELAY_PIPER_PROTOTYPE_PLAN.md)
- [Relay Piper Voice Model Selection](RELAY_PIPER_VOICE_MODEL_SELECTION.md)
