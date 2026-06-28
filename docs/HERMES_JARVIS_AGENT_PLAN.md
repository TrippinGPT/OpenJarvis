# Hermes / Jarvis Agent Plan

This document is the source of truth for the first practical Hermes and Jarvis split inside Trippin AI Relay.

## Purpose

Define a clean first-wave architecture that keeps Hermes, Jarvis, and the first specialist agents in distinct lanes.

The goal is not a generic AI operating system. The goal is a safe local shell with a clear talk layer and a narrow first-wave helper set.

## System Overview

- Hermes is the shell.
- Jarvis is the front-facing talk layer.
- Dispatch is the routing and coordination helper.
- Recon is the research and summary helper.
- Patch is the build / fix / script / repo helper in propose-only mode.

This first phase is about configuration and wiring shape. It is not a full autonomous multi-agent runtime.

## User Sees vs. System Does

### User sees

- one front-facing Jarvis-style conversational layer
- clear next-step framing
- safe handoff language
- a small number of specialist helpers when needed

### System does

- Hermes runs preflight and readiness checks
- Hermes reports local status
- Hermes handles launcher and restart readiness
- Hermes records safe status and logging context
- Dispatch decides whether the task should stay simple or move to a first-wave worker
- Recon prepares evidence-first summaries
- Patch prepares safe propose-only build or fix plans

## Hermes Shell

Hermes owns:

- preflight
- launcher and restart readiness
- local status
- safe handoff
- logging
- status reporting

Hermes does not own:

- the main reasoning brain
- the routing brain
- the conversation layer
- the code-writing specialist role

Hermes should stay light-touch, operational, and local-first.

## Jarvis Talk Layer

Jarvis owns:

- front-facing conversational wrapper
- tone
- user-facing handoff language
- “what next” framing

Jarvis does not own:

- routing policy
- specialist ownership
- repo execution
- shell control

Jarvis should never duplicate Dispatch logic. It should present the system cleanly, not secretly replace it.

## First-Wave Subagents

### Dispatch

Dispatch owns:

- routing
- coordination
- deciding which first-wave worker fits
- sequencing simple multi-step flow when needed

Dispatch does not own:

- research output itself
- repo fix execution itself
- launcher / readiness operations

### Recon

Recon owns:

- research
- summaries
- fact gathering
- evidence-first output structure

Recon does not own:

- routing decisions
- build or fix work
- speculative claims presented as verified facts

### Patch

Patch owns:

- build work
- fix planning
- script / repo work
- proposed diff shape
- validation-command planning

Patch stays in propose-only mode.

Patch does not own:

- destructive execution
- commit automation
- tag automation
- push automation
- approval bypass

## Ownership Matrix

| Concern | Hermes | Jarvis | Dispatch | Recon | Patch |
| --- | --- | --- | --- | --- | --- |
| Preflight | owner | present status | no | no | no |
| Launcher / restart readiness | owner | no | no | no | no |
| Local status / logging | owner | no | no | no | no |
| Conversational wrapper | no | owner | no | no | no |
| User-facing handoff phrasing | assist | owner | assist | no | no |
| Routing / coordination | no | no | owner | no | no |
| Research / summaries | no | wrapper only | route only | owner | no |
| Build / fix / script / repo proposals | no | wrapper only | route only | no | owner |
| Destructive actions | no | no | no | no | no |
| Commit / tag / push automation | no | no | no | no | no |

## What Stays Manual

The following stay manual:

- destructive actions
- risky changes
- approvals
- commit / tag / push
- anything touching `D:\AI\OPENCLAW`

Patch may prepare a fix summary, proposed diff shape, or validation path. It must not auto-ship changes.

## First Real Test Tasks

The first test path for this architecture is:

1. summarize current project state
2. route an unclear task to the right helper
3. fix one real script or workflow issue in a safe propose-only way

## Second-Wave Subagents (later only)

Later-only specialists may include:

- Redline
- Veto
- Racket

They are intentionally out of first-wave scope.

## Boundaries / What This Is Not

This is not:

- a shell fork
- a generic AI OS
- a full autonomous multi-agent system
- a microphone or voice capture project
- a risky automation layer

This first phase must not:

- add destructive actions
- add commit / tag / push automation
- add microphone or audio capture changes
- add autoplay changes
- modify `D:\AI\OPENCLAW`

## Build Order

1. lock the authority document
2. define Hermes shell ownership
3. define Jarvis talk-layer ownership
4. define Dispatch / Recon / Patch role configs
5. define safe handoff and routing shape
6. document first real test paths

## First-Phase Success Criteria

The first phase is successful when:

- Hermes ownership is clearly separated from Dispatch, Recon, and Patch
- Jarvis talk is clearly separated from Dispatch routing
- Dispatch, Recon, and Patch each have a practical config / prompt / role definition
- manual-only boundaries are explicit
- the first three test tasks can be run through a documented path

## What Would Justify a Later Shell Fork

A later shell fork is justified only if:

- Hermes can no longer stay a thin shell
- the shell needs architecture changes that the current Hermes ownership cannot express cleanly
- routing, status, and handoff needs fundamentally exceed the current shell boundaries
- first-wave and second-wave agent behavior require deeper runtime control than safe config and prompt layers can provide

Until then, the preferred path is configuration, prompts, and safe wiring rather than a shell rewrite.
