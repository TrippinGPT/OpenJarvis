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

Stop:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\stop_relay_stack.ps1
```

Restart:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\restart_relay_stack.ps1
```

The launcher starts:

- Backend: [http://127.0.0.1:8000/](http://127.0.0.1:8000/)
- Frontend: [http://localhost:5173/](http://localhost:5173/)

After startup, the launcher prints the ready URLs and waits for manual browser open.

The stop and restart scripts target Relay frontend and backend first. Ollama is left alone unless `-IncludeOllama` is passed and the stack recorded Relay-owned Ollama in its local state file.

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
- Relay voice milestone summary
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
- v3.4.1 fixes the popout voice API wiring so `/api/relay/voice/config` and `/api/relay/voice/play` resolve correctly through the backend and the frontend proxy.
- v3.4.2 freezes the current voice/UI lane as the stable placeholder milestone for now.
- v3.5 improves Relay’s non-voice personality layer across popout, dashboard, and status microcopy so the companion tone holds even with voice disabled.
- v3.6 adds a light multi-agent identity layer so every specialist now has defined text style and placeholder voice direction without adding runtime speech.
- v3.6.1 surfaces that multi-agent identity layer directly in the Agents UI so the team reads like distinct operators instead of flat labels.
- v3.6.2 adds per-agent response framing in the Agents UI so each specialist now presents its context in a visibly different style, not just different metadata.
- v3.6.3 adds a dedicated per-agent voice planning document so future specialist placeholder speech has a defined strategy before any runtime implementation.
- v3.6.4 adds light per-agent behavior hooks in the product so each specialist now exposes lane-specific stance, interpretation, and next-step cues without autonomous execution.
- v3.6.5 tightens the multi-agent layer so the specialist identities, sample lines, and `/agents` framing read as a cleaner, more distinct operator team.
- v3.7 adds a Discord structure and dev-onboarding plan so the ecosystem has a cleaner front door, clearer active-versus-parked lane map, and a usable builder entry point.
- v3.8 adds a SlapDesk workflow/product overview so the music lane now reads like a deliberate product lane instead of a parked concept.
- v3.8.1 adds the first SlapDesk workflow packet so the music lane now includes practical checklists, templates, and a usable session path from cookup to bounce.
- v3.9 adds a consolidated PaperLab overview so the paper-trading education lane now has a cleaner naming hierarchy, workflow shape, and safety-first scope.
- v3.9.1 adds the first PaperForge workflow packet so the paper-learning lane now includes practical scenario, logging, review, and discipline templates for fake-money drills.
- v3.9.2 adds the first PaperForge scenario pack so the paper-learning lane now includes reusable fake-money drill scenarios, filled example cards, and a starter sequence for disciplined practice.
- v4.0 adds a master ecosystem roadmap so lane priority, build sequencing, maintenance responsibilities, and parked-versus-later work are explicit in one place.
- v4.0.1 refreshes the ecosystem roadmap so Relay's memory-driven product lane stays primary, PaperLab / PaperForge moves into light maintenance, and SlapDesk remains intentionally parked.
- v4.1 adds a Mem0 fit evaluation for Relay memory and recommends starting with a smaller structured memory layer before any heavier semantic memory foundation.
- v4.1.1 adds the first local structured Relay memory prototype with explicit transient fields, visible pinned notes, 12-hour expiry, and operator clear/reset controls in the Relay Companion.
- v4.1.2 tightens the structured memory prototype so status refresh no longer stomps better task continuity, the popout panel groups transient versus pinned versus workspace memory more clearly, and session/hygiene metadata is de-emphasized instead of driving the main operator view.
- v4.1.3 makes `nextSuggestedMove` come from deterministic structured-memory guidance instead of repeated hardcoded action strings, using lane, agent, objective, status, pinned notes, and workspace priorities as explicit inputs.
- v4.1.4 adds deterministic memory-informed routing guidance so Relay can suggest a best next agent or a stable stay-with-current-agent outcome, with visible handoff reasoning and no auto-switching.
- v4.1.5 adds a local-only usage review log in the Relay Popout so the operator can save short cockpit feedback entries with visible current context and clear/reset controls.
- v4.1.6 adds a local-only usage review digest and tuning hint so recent feedback can be summarized into strong, mixed, rough, and likely-next-polish signals without adding analytics infrastructure.
- v4.1.7 adds local stop/restart control scripts so the Relay frontend and backend can be shut down and relaunched cleanly without manual process hunting.
- v4.2 adds a Simple Mode in the Relay Popout so the cockpit defaults to a clearer task-first flow with one main input, one recommended agent, one next action, and Advanced mode kept behind an explicit toggle.
- v4.3.1 adds the missing Hermes / Jarvis authority document plus a first-wave config layer for Dispatch, Recon, and Patch, with Hermes kept on shell ownership and Patch kept in propose-only mode.
- v4.3.2 tunes the first-wave model routing so Hermes and Jarvis stay on `hermes3:8b`, Dispatch and Recon move to `qwen3.5:9b`, and Patch uses `qwen2.5-coder:14b` for faster, sharper, and more bounded behavior.
- v4.4 adds the full OpenJarvis × Hermes Desktop × Relay fork blueprint so product direction, inheritance map, first-wave scope, phased build order, and success criteria are locked in one place.
- v4.4.1 builds the canonical Relay Simple Mode shell so `/relay-popout` is the default fork entry, the companion defaults to a calm task-first layout, and first-wave agent clarity is limited to Dispatch, Recon, and Patch in the quick guide.
- v4.4.2 tightens Simple Mode first-wave behavior so normal task routing prefers Dispatch, Recon, and Patch, explains why the recommended specialist fits, and keeps Hermes or later-phase agents out of the default flow unless advanced shell/readiness context truly warrants them.
- v4.4.3 revamps the default Relay front door toward a calmer Hermes Desktop-style assistant shell: one main task surface, one recommended first-wave worker, one next action, and deeper cockpit internals behind detail controls or Advanced mode.
- v4.4.4 fixes Simple Mode task flow so Clear is deterministic, first-wave handoff buttons queue a real task, and `/relay-popout` now feeds the live `/chat` path instead of stopping at draft-only routing copy.
- v4.4.5 tightens first-wave chat behavior after the new Simple Mode handoff flow so Dispatch, Recon, and Patch each switch the live chat model, carry stricter first-wave instructions into `/chat`, and answer in a more role-shaped format instead of falling back toward generic assistant output.
- v4.4.6 fixes first-wave worker recommendation so explicit project-state, summary, repo-state, and evidence-first asks bias to Recon before stale memory or generic build context can pull the shell toward Patch.
- v4.4.7 fixes Patch popout task flow by resolving the Patch handoff model against the actual installed model list before `/chat` submit, so Patch keeps its propose-only coder lane even when one exact preferred model ID is not present.
- See [RELAY_VOICE_MILESTONE_SUMMARY.md](RELAY_VOICE_MILESTONE_SUMMARY.md) for the voice-lane timeline, winners, losses, and current stable behavior.

### Voice/UI freeze note

- The current Relay voice/UI lane is stable for now.
- Active placeholder voice: `af_bella`
- Active placeholder mode: `sarcastic`
- Active placeholder style: `sarcastic_polish_04`
- Current popout behavior is the frozen baseline: manual playback, category preview, event gates, and real-action hooks.
- The written personality layer now matches the same sharp, controlled command-center tone without depending on voice playback.
- Dispatch, Recon, Patch, Redline, Racket, Hermes, and Veto now have explicit identity fields for UI cards, docs, and future per-agent voice planning.
- Relay Companion is still the only implemented runtime placeholder voice; the other agents now have documented voice direction only.
- Relay Popout now defaults to Simple Mode for friendlier scanning; Advanced mode still exposes memory, routing, review, and voice internals on demand.
- The fork default frontend entry now redirects to `/relay-popout`; OpenJarvis chat remains at `/chat`.
- See [Relay Fork Simple Mode](RELAY_FORK_SIMPLE_MODE.md) for the canonical Phase 2 shell behavior.
- See [Relay GUI Revamp](RELAY_GUI_REVAMP.md) for the v4.4.3 front-door simplification notes.
- Simple Mode now acts as a real operator front door: the main task box can hand off directly into the existing chat flow, and first-wave worker buttons queue a live chat request instead of acting as decorative routing labels.
- First-wave chat handoff now also sets the specialist model before submit and carries stricter worker-specific output rules into the live `/chat` request: Dispatch stays in short owner/why/next routing form, Recon stays evidence-first and local-project-first, and Patch stays propose-only with files, validation, and risks.
- Hermes, Jarvis, Dispatch, Recon, and Patch now have a documented first practical split for shell ownership, conversational wrapper ownership, routing, research, and propose-only repo work.
- Simple Mode now treats Dispatch, Recon, and Patch as the active first-wave operator path: Dispatch routes unclear work, Recon handles evidence/project-state work, and Patch handles propose-only build/fix work.
- The fork blueprint in [OPENJARVIS_HERMES_RELAY_FORK_PLAN.md](OPENJARVIS_HERMES_RELAY_FORK_PLAN.md) is now the product-direction authority for what stays OpenJarvis foundation, what borrows Hermes Desktop UX patterns, and what the Relay twist adds.
- See [Relay First-Wave Chat Behavior](RELAY_FIRST_WAVE_CHAT_BEHAVIOR.md) for the runtime handoff shape, live model split, and expected Dispatch / Recon / Patch output discipline.
- Future work should start from a deliberate new milestone, not ad hoc polish changes.

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
- **v3.4.1:** Voice API wiring fix
- **v3.4.2:** Freeze current voice/UI milestone
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
- [Relay Voice Milestone Summary](RELAY_VOICE_MILESTONE_SUMMARY.md)
- [Relay Memory Prototype](RELAY_MEMORY_PROTOTYPE.md)
- [Relay Simple Mode](RELAY_SIMPLE_MODE.md)
- [Relay GUI Revamp](RELAY_GUI_REVAMP.md)
- [Hermes / Jarvis Agent Plan](HERMES_JARVIS_AGENT_PLAN.md)
- [Hermes First-Wave Setup](HERMES_FIRST_WAVE_SETUP.md)
- [OpenJarvis Hermes Relay Fork Plan](OPENJARVIS_HERMES_RELAY_FORK_PLAN.md)
- [Relay Fork Simple Mode](RELAY_FORK_SIMPLE_MODE.md)
