# Relay Fork Simple Mode

This document describes the canonical Simple Mode shell for the OpenJarvis × Hermes Desktop × Relay fork.

Authority:

- [OPENJARVIS_HERMES_RELAY_FORK_PLAN.md](OPENJARVIS_HERMES_RELAY_FORK_PLAN.md) — Phase 2
- [RELAY_SIMPLE_MODE.md](RELAY_SIMPLE_MODE.md) — original Simple Mode intent

## Product entry

The fork default route is `/relay-popout`.

When the frontend loads at `/`, it redirects to the Relay companion shell. OpenJarvis chat remains available at `/chat`.

Simple Mode is enabled by default through `relaySimpleModeEnabled: true` in frontend settings.

## What Simple Mode shows

Simple Mode is built around three operator questions:

1. **What do I type here?** — plain-language task input with save/clear controls
2. **Who is handling this?** — one recommended specialist, why it fits, and a handoff action
3. **What should I do next?** — deterministic next-move guidance from structured memory

It also shows:

- a compact first-wave team guide for **Dispatch**, **Recon**, and **Patch**
- a minimal current-focus line when memory already has an objective or status
- a calm header with local online/readiness state
- footer links to Dashboard, Agents, and Chat
- one obvious **Show advanced** path

## What Simple Mode hides

Simple Mode does not remove capability. It hides visual and panel complexity until Advanced mode:

- radar HUD and side micro-readouts
- telemetry strip
- recent status / signal / command panels
- structured memory internals
- routing detail blocks
- usage review log and digest
- placeholder voice controls
- secondary debug and telemetry clutter

## First-wave agent clarity

Simple Mode surfaces only the active first-wave specialists in the quick guide:

| Agent | Role in Simple Mode |
|---|---|
| Dispatch | Routing and coordination |
| Recon | Research, summaries, and facts |
| Patch | Build, fix, propose-only |

Hermes remains the documented shell role for readiness and status, but the quick guide stays focused on the three runtime specialists.

Redline, Veto, Racket, and other roster agents are not promoted in Simple Mode. They may still appear as routing recommendations when safety or readiness signals require it, but they are not presented as active first-wave operators.

## Advanced mode

Advanced mode restores the full Relay companion cockpit:

- radar HUD
- telemetry and status panels
- structured memory editor
- routing guidance detail
- usage review tools
- placeholder voice lane

The header **Simple** button returns to Simple Mode without losing settings or memory.

## Implementation map

| Piece | Location |
|---|---|
| Simple Mode shell UI | `frontend/src/components/Relay/RelaySimpleModeShell.tsx` |
| Popout page wiring | `frontend/src/pages/RelayPopoutPage.tsx` |
| First-wave agent constants | `frontend/src/data/relayFirstWaveAgents.ts` |
| Default route redirect | `frontend/src/App.tsx` |
| Sidebar companion entry | `frontend/src/components/Sidebar/Sidebar.tsx` |
| Calm Simple Mode styling | `frontend/src/index.css` |

## Boundaries

This milestone is Phase 2 only.

It does not add:

- new agents
- runtime tool execution
- autonomous orchestration
- microphone or autoplay changes
- OpenClaw modifications
