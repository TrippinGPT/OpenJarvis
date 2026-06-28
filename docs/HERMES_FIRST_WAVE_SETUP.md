# Hermes First-Wave Setup

This document explains the first practical Hermes-side setup for the Relay first wave:

- Dispatch
- Recon
- Patch

Authority:

- [HERMES_JARVIS_AGENT_PLAN.md](HERMES_JARVIS_AGENT_PLAN.md)

## What this setup adds

- one machine-readable first-wave config
- one Jarvis talk-layer wrapper prompt
- one role prompt for each first-wave specialist
- a documented test path

## File layout

- `config/hermes_first_wave_agents.json`
- `configs/openjarvis/prompts/personas/jarvis-relay-first-wave.md`
- `configs/openjarvis/prompts/relay_first_wave/dispatch.md`
- `configs/openjarvis/prompts/relay_first_wave/recon.md`
- `configs/openjarvis/prompts/relay_first_wave/patch.md`

## Implemented ownership

### Hermes

Hermes owns:

- preflight
- launcher and restart readiness
- local status
- safe handoff
- logging / status reporting

### Jarvis talk

Jarvis owns:

- front-facing tone
- user-facing handoff language
- conversational wrapper
- “what next” framing

### Dispatch

Dispatch owns:

- routing
- coordination
- simple step ordering

### Recon

Recon owns:

- research
- summaries
- evidence-first context gathering

### Patch

Patch owns:

- build / fix / script / repo proposals
- validation planning
- propose-only change framing

## What stays manual

- destructive actions
- risky execution
- approvals
- commit / tag / push
- anything touching `D:\AI\OPENCLAW`

## First-wave test path

### 1. Summarize current project state

Use Jarvis talk as the front door, then route to Recon if facts need to be gathered or cleaned up.

Expected shape:

- Hermes reports local readiness if needed
- Dispatch decides whether this is simple status framing or a Recon task
- Recon returns an evidence-first summary

### 2. Route an unclear task to the right helper

Use Dispatch first.

Expected shape:

- Jarvis presents the request cleanly
- Dispatch decides whether the task belongs to Recon, Patch, or should stay at coordination level
- Hermes only supports safe handoff and local status if needed

### 3. Fix one real script or workflow issue in a safe propose-only way

Use Patch.

Expected shape:

- Patch identifies the smallest safe change
- Patch proposes the change and validation commands
- destructive execution, commit, tag, and push stay manual

## Validation checklist

- first-wave roles are distinct
- Hermes is not acting as the routing brain
- Jarvis is not duplicating Dispatch logic
- Patch remains propose-only
- no OpenClaw changes are introduced
