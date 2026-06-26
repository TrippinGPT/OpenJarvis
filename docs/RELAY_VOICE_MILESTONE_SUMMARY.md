# Relay Voice Milestone Summary

## Purpose

This document records how Relay voice moved from early local TTS experiments into the current stable placeholder voice system. It captures what won, what lost, what the UI currently does, and what remains future work.

## Final current state

- Winning local TTS lane: Kokoro
- Current active placeholder voice: `af_bella`
- Current active placeholder mode: `sarcastic`
- Current placeholder pack:
  - default: `sarcastic_polish_04`
  - secondary: `sarcastic_polish_03`
  - backup: `sarcastic_polish_02`
- Voice remains off by default
- No autoplay on page load
- No microphone or audio capture
- No always-on listening
- Playback remains local, gated, and user-controlled
- Current voice surface: `/relay-popout`
- Milestone status: frozen stable placeholder baseline

## Timeline and milestone progression

### v1.7 through v1.9: planning and feasibility

- Voice identity, safety rules, and candidate lanes were documented first.
- Read-only feasibility and setup checks were added before runtime work.
- Piper was chosen as the first technical prototype lane.

### v2.0 through v2.4.5: Piper proved the path, but lost the fit test

- Piper sandboxing, runtime setup, gated model selection, and first WAV generation were completed.
- Piper proved the local/offline technical path.
- Multiple Piper candidates were reviewed.
- Final result: Piper worked technically, but did not win the final Relay voice fit.

### v2.5 through v2.5.9: Kokoro became the winning lane

- Kokoro prerequisite checks, venv setup, first WAV testing, and voice/style sweeps were added.
- `af_bella` emerged as the best current local voice.
- `sarcastic` emerged as the strongest current delivery mode.
- Smartmouth formatting, cadence, punch, and sarcastic polish were layered on top of Kokoro output.

### v2.5.10 through v2.5.11: startup and placeholder pack stabilization

- Relay startup flow was fixed so backend/frontend readiness behaved correctly.
- Browser auto-open was removed from the launcher path.
- The current placeholder pack was locked from sarcastic polish results.

### v3.0 through v3.4: gated UI wiring

- Manual placeholder playback was added to `/relay-popout`.
- Category-based placeholder selection and category variants were added.
- Event trigger toggles were added.
- Event trigger UX was refined so dropdown browsing became preview-only.
- Real-action hooks were added for selected event playback and live status refresh.

### v3.4.1 through v3.4.2: wiring fix and freeze

- The voice API pathing was corrected so the popout receives backend JSON instead of the SPA shell.
- The current voice/UI lane is now frozen as the stable placeholder milestone.

## Piper phase summary

### What Piper proved

- Local offline TTS was viable on the Relay machine.
- Relay-local sandboxing and gating worked.
- Gated WAV generation and review workflows worked.

### Why Piper lost

- Final voice fit was not good enough for Relay Companion / Smartmouth Relay.
- It validated the engineering path, but not the final persona target.

### Piper result

- Technical winner for proof-of-path
- Final loser for voice fit

## Kokoro phase summary

### What Kokoro won

- Best current local TTS quality-to-persona balance
- Best current fit for short, sarcastic command-center delivery
- Best current lane for continued placeholder voice work

### Kokoro result

- Winning local TTS lane
- Current stable local placeholder runtime

## Winning voice and mode

- Active placeholder voice: `af_bella`
- Active placeholder mode: `sarcastic`
- Active placeholder style: `sarcastic_polish_04`

Current locked speaking direction:

- short
- punchy
- sarcastic but controlled
- command-center assistant energy
- original delivery only

## Smartmouth delivery evolution

### Formatting

- Long written lines were split into shorter spoken fragments.
- Filler language was reduced.
- Spoken rhythm was prioritized over paragraph-style text.

### Cadence

- Pause and emphasis hints were added.
- Delivery was tuned to feel faster and more alive.

### Sarcastic polish

- Broad mode exploration narrowed down to the winning sarcastic lane.
- Short-form punch beat softer dry/command alternatives.

## UI integration evolution

### Initial UI wiring

- Manual playback toggle
- Manual play button
- Voice off by default

### Category system

- Placeholder category selector
- Category preview
- Category variants

### Event system

- Event gate toggles for startup, routing, success, and warning
- Explicit event trigger UX
- Preview-only browsing so category changes do not speak

### Current real-action hooks

- Startup can fire from `Voice On` when the startup gate is enabled.
- `Run Selected Event` can speak the selected `routing`, `success`, or `warning` category when its gate is enabled.
- `Refresh Relay Status` can speak `success` on healthy refresh or `warning` on fallback/unavailable refresh when the matching gate is enabled.

## Current safety model

- Voice is off by default.
- No autoplay on initial page load.
- No microphone or audio capture.
- No always-on listening.
- No OpenClaw changes.
- No cloud TTS.
- No voice cloning.
- No arbitrary browser shell execution.
- Playback is local and user-triggered.
- Single-flight playback protection prevents stacked duplicate requests.

## Current placeholder categories and variants

### startup

- `Relay online. Try not to break anything expensive.`
- `Relay online. Keep the damage optional.`

### routing

- `Routing now. Don't screw it up...`
- `Routing now. Don't make it ugly.`

### success

- `Relax. I already fixed it.`
- `Handled. You're welcome.`

### warning

- `We HAVE a plan. Don't sabotage it...`
- `Bad idea. Let's not do that.`

### manual_test

- `Relay online. Voice check complete.`
- `Voice check complete. Still functional.`

## Startup and launcher status

- Relay launcher flow was fixed.
- Browser no longer auto-opens during normal startup.
- Startup now waits on service readiness and keeps the flow quieter.
- Voice startup behavior remains gated and optional inside the popout UI.

## What remains future work

- Treat the current milestone as stable-for-now. Resume only through a deliberate new milestone, not random polish.
- Non-voice companion behavior can keep evolving through deliberate UI/personality milestones without reopening the voice plumbing itself.
- Decide whether the current placeholder pack should remain long-term or be replaced by a more final production voice.
- Refine real-action voice mapping further without making the UI noisy.
- Add more contextual action-to-line selection only where the action is real, explicit, and safe.
- Evaluate agent-specific voice identity only if the system still remains original and controlled.
- Keep all future speech local, gated, and user-controlled unless a later task explicitly changes that boundary.
