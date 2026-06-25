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

After startup, the launcher prints the ready URLs and waits for manual browser open.

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
- `relay-v2.4-first-piper-test-wav`
- `relay-v2.4.1-piper-audio-review`
- `relay-v2.4.2-piper-voice-comparison`
- `relay-v2.4.3-piper-amy-tuning`
- `relay-v2.4.5-piper-danny-test`
- `relay-v2.5-kokoro-feasibility`
- `relay-v2.5.1-kokoro-prereqs`
- `relay-v2.5.2-kokoro-venv-setup`
- `relay-v2.5.3-kokoro-first-wav`
- `relay-v2.5.4-kokoro-voice-sweep`
- `relay-v2.5.4.1-kokoro-sweep-runner-fix`
- `relay-v2.5.5-smartmouth-delivery`
- `relay-v2.5.6-smartmouth-cadence`
- `relay-v2.5.9-sarcastic-polish`
- `relay-v2.5.10-startup-fix`
- `relay-v2.5.10.2-quiet-launcher`
- `relay-v3.0-placeholder-voice-ui`

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
- First gated Kokoro WAV test runner
- Gated Kokoro voice/style comparison sweep
- Kokoro voice sweep runner with explicit venv Python validation
- Isolated Python 3.11 Piper installation under `tools\piper.venv`
- Approved Piper voice-model gate with local files under `tools\piper\voices`
- First gated local Relay test WAV under `outputs\tts_tests`
- Gated Kokoro venv setup lane with Kokoro installed in `tools\kokoro.venv`

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
- A first gated Kokoro WAV has been generated locally and now serves as the baseline for a voice/style comparison sweep.
- Piper is installed locally; Kokoro is installed locally in `tools\kokoro.venv`.
- The local TTS feasibility check passed for a planning-only prototype.
- The Kokoro prerequisite checker now reports ready for future gated setup.
- v2.5.2 created `tools\kokoro.venv` and installed `kokoro` 0.9.4 locally without generating audio.
- v2.5.3 generated `outputs\tts_tests\relay_kokoro_first_20260623_161539.wav` using the gated Kokoro runner.
- v2.5.4 adds a gated Kokoro voice/style comparison sweep using several official Kokoro voices against several Smartmouth Relay lines.
- v2.5.4.1 fixes the Kokoro sweep runner so it accepts an explicit `-PythonExe` and validates the Kokoro venv interpreter directly.
- v2.5.5 adds the Smartmouth delivery pack and a gated Kokoro Smartmouth test runner for short, punchy TTS-optimized lines.
- v2.5.6 adds cadence and timing metadata so Smartmouth lines can carry pause and emphasis hints into Kokoro synthesis.
- v2.5.9 narrows the lane to sarcastic-only polish for `af_bella`.
- The Kokoro cache now lives under `tools\kokoro\models` and remains ignored by Git.
- The Piper prototype plan and read-only setup checker exist.
- v2.0 prepares only the Relay-local Piper and TTS-test sandbox folders.
- v2.1 adds gated scripts only. The install gate is a manual-review placeholder.
- v2.1.1 inventories local Python runtimes before installation. Python 3.11 is preferred and Python 3.12 is acceptable.
- This machine defaults to Python 3.14.5; the launcher also reports Python 3.12 and uv-managed CPython 3.11.15.
- v2.2 created `tools\piper.venv` with Python 3.11.15 and installed `piper-tts` 1.4.2 locally.
- v2.2.1 verified `tools\piper.venv` as the canonical active path; legacy `tools\piper\.venv` is absent and unused.
- v2.3 adds the approved local test voice `en_US_lessac_medium` and the gated download script.
- Voice-model files live only under `tools\piper\voices` and remain ignored by Git.
- v2.4 gates the first local test WAV and keeps the generated audio local/ignored.
- v2.4.1 reviewed the first WAV and rejected `en_US_lessac_medium` as the final Relay voice.
- v2.4.2 adds a gated comparison lane for `en_US_lessac_medium`, `en_US_amy_medium`, and `en_US_ljspeech_medium`.
- v2.4.3 adds an Amy-only tuning lane based on the comparison review.
- v2.4.5 adds a Danny candidate gate based on the Piper samples page.
- v2.5 adds a Kokoro feasibility lane after the Piper fit failures.
- v2.5.1 adds Kokoro prerequisite prep before any install.
- v2.5.2 adds a gated Kokoro venv setup lane. No audio generation or runtime TTS has happened yet.
- v2.5.3 adds the first gated Kokoro WAV test runner and keeps audio generation local and ignored.
- v2.5.4 adds the gated Kokoro voice/style comparison sweep.
- v2.5.4.1 fixes Kokoro sweep runner Python selection and venv detection.
- v2.5.5 adds the Smartmouth delivery pack.
- v2.5.6 adds Smartmouth cadence/timing metadata and rendered pause control.
- v2.5.9 adds a sarcastic-only Relay polish lane.
- v2.5.10 fixes startup sequencing so the backend is ready before the frontend is treated as ready.
- v2.5.10.2 makes the desktop launcher quiet and manual-open only.
- v2.5.11 locks the placeholder voice pack to the sarcastic polish results.
- v3.0 adds gated placeholder Relay voice wiring to the popout UI.
- Current polish target: `af_bella` in `sarcastic` mode.
- Placeholder pack target: `sarcastic_polish_04`.
- No Piper package was installed globally.
- The selected voice-model pair lives under `tools\piper\voices` and no audio has been generated.
- Generated WAV files are local test artifacts and ignored by Git.
- No Relay Popout voice toggle or automatic speech exists.
- No app runtime TTS exists yet.
- Model download, audio generation, playback, or UI voice controls require explicit user approval in a future task.
- The current placeholder pack is locked to the sarcastic polish results: default `sarcastic_polish_04`, secondary `sarcastic_polish_03`, backup `sarcastic_polish_02`.
- Placeholder voice playback is available only behind a manual popout toggle and play button, and remains off by default.
- v3.2.1 tightens the event/demo placeholder wording without changing the gated manual behavior.
- v3.3 maps startup, routing, success, and warning playback to explicit safe popout actions while keeping the same opt-in gates.
- v3.3.1 makes category browsing preview-only so dropdown changes do not speak by themselves.
- v3.4 adds explicit real-action hooks for selected events and live Relay status refresh inside the popout.

### v2.5 milestone note

- Kokoro feasibility is now the next local/offline TTS lane.
- No Kokoro install has happened yet.
- No new audio or model downloads were performed for Kokoro.
- Piper remains the baseline only; the final Relay voice is still unresolved.

### v2.5.1 milestone note

- Kokoro prerequisite prep is now documented separately.
- Default Python is 3.14.5.
- `py -3.11` does not resolve, but uv-managed CPython 3.11.15 is available and satisfies the Kokoro Python prereq.
- `espeak-ng` is installed and available at `C:\Program Files\eSpeak NG\espeak-ng.exe`.
- No Kokoro install, model download, or audio generation has happened.

### v2.5.2 milestone note

- Kokoro prerequisites are satisfied.
- The gated Kokoro venv setup has completed.
- `tools\kokoro.venv` now exists and contains `kokoro` 0.9.4.
- No audio generation or runtime TTS has happened.

### v2.5.3 milestone note

- The first gated Kokoro WAV runner is available.
- The baseline first-test voice is `af_heart`.
- The Smartmouth Relay planning line is the first local Kokoro test line.
- The first WAV file was generated locally and remains ignored by Git.
- Audio generation remains local, gated, and ignored by Git.

### v2.5.4 milestone note

- The first Kokoro WAV is now the baseline for a local voice/style comparison sweep.
- The sweep compares several official Kokoro voices against several Smartmouth Relay planning lines.
- No app/runtime TTS or voice toggle has been added.
- Smartmouth line formatting now exists as a separate delivery layer for Kokoro tests.
- `af_bella` is the current Smartmouth delivery voice.
- Smartmouth timing now includes pause and emphasis metadata for the runner.
- `sarcastic` is the active polish mode; `dry` and `command` remain available but are not the current target.
- Placeholder voice playback is gated to a popout UI toggle and play button.

### v2.4.1 milestone note

- First local Piper WAV was reviewed.
- `en_US_lessac_medium` was rejected as the final Relay voice because it sounded too robotic and did not fit the persona well enough.
- The pipeline remains useful for future comparison testing and controlled voice selection.

### v2.4.2 milestone note

- A gated local comparison lane is available for `en_US_lessac_medium`, `en_US_amy_medium`, and `en_US_ljspeech_medium`.
- The comparison lane remains offline and does not integrate voice into the app.

### v2.4.3 milestone note

- Amy is now the best current candidate.
- LJSpeech is rejected.
- Lessac remains only a technical baseline.
- Amy tuning is local-only and still not app-integrated.

### v2.4.5 milestone note

- Danny is the next candidate under test.
- The target is a polished human command-center assistant feel, not a cloned character.
- Runtime/app TTS is still blocked until a voice is approved.
- Kokoro feasibility is the next lane after Danny.

## 9. Next possible milestones

- **v2.3:** Approved Piper voice-model selection/download gate
- **v2.4:** First gated local test WAV
- **v2.5:** Kokoro feasibility lane
- **v2.5.1:** Kokoro prerequisite prep
- **v2.5.2:** Kokoro gated venv setup
- **v2.5.3:** First gated Kokoro WAV test
- **v2.5.4:** Kokoro voice/style comparison sweep
- **v2.5.4.1:** Kokoro sweep runner fix
- **v2.5.5:** Smartmouth delivery pack
- **v2.5.6:** Smartmouth cadence layer
- **v2.5.9:** Sarcastic polish lane
- **v3.0:** Gated placeholder Relay voice UI
- **v3.1:** Contextual placeholder line selection
- **v3.1.1:** Placeholder line variants
- **v3.2:** Gated UI event triggers
- **v3.2.1:** Event line wording polish
- **v3.3:** Gated event-to-action mapping
- **v3.3.1:** Event trigger UX polish
- **v3.4:** Real-action voice hooks
- **v3.5:** Agent-specific original voice profiles
- **v3.6:** Real routing signals connected to agent mesh animation
- **v3.7:** Safe preflight actions

These are proposed milestones only. They do not authorize installation, downloads, audio generation, agent execution, or OpenClaw changes.

## 10. Useful commands

Run from `D:\AI\TRIPPIN_AI_RELAY`:

```powershell
git status --short
git --no-pager log --oneline -10
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_openclaw_bridge.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_relay_tts_feasibility.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_setup.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_kokoro_feasibility.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_kokoro_prereqs.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_first_wav_gated.ps1 -AllowModelDownload -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -PythonExe D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_voice_sweep_gated.ps1 -AllowModelDownload -AllowGenerate -PythonExe D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\format_smartmouth_lines.ps1 -Line "Routing that now. Shocking development: we are using a plan." -Mode sarcastic
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_smartmouth_test_gated.ps1 -Line "Routing that now. Shocking development: we are using a plan."
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_smartmouth_test_gated.ps1 -Line "Routing that now. Shocking development: we are using a plan." -Mode sarcastic -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_sarcastic_polish_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_kokoro_sarcastic_polish_gated.ps1 -AllowGenerate
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\download_piper_voice_model_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\download_piper_voice_model_gated.ps1 -AllowDownload
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1 -AllowGenerate
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
- [Relay Piper Voice Comparison](RELAY_PIPER_VOICE_COMPARISON.md)
- [Relay Piper Amy Tuning](RELAY_PIPER_AMY_TUNING.md)
- [Relay Piper Voice Model Selection](RELAY_PIPER_VOICE_MODEL_SELECTION.md)
- [Relay Kokoro TTS Plan](RELAY_KOKORO_TTS_PLAN.md)
- [Relay Kokoro Voice/Style Sweep](RELAY_KOKORO_VOICE_SWEEP.md)
- [Relay Smartmouth Delivery Pack](RELAY_SMARTMOUTH_DELIVERY.md)
