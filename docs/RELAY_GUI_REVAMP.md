# Relay GUI Revamp

## Purpose

Relay v4.4.3 shifts the default front door away from a dense cockpit view and closer to a calm Hermes Desktop-style assistant shell.

The goal is not to remove Relay capability. The goal is to make the first screen obvious:

1. type the task
2. see the recommended first-wave worker
3. see the next action
4. open Advanced only when deeper controls are needed

## Default front-door shape

The default `/relay-popout` Simple Mode now prioritizes:

- a central main task surface
- one recommended first-wave worker
- one short reason for that recommendation
- one clear next action
- minimal visible status

The default view intentionally avoids showing all memory internals, routing internals, usage review, voice controls, and diagnostic/status panels at once.

## First-wave focus

Simple Mode keeps normal work inside the first-wave team:

- Dispatch: unclear work, coordination, route selection, sequencing
- Recon: research, summaries, facts, evidence-first project/context work
- Patch: build, fix, script, repo, workflow, and validation work in propose-only mode

Hermes, Jarvis, and later agents are still part of the broader Relay plan, but they are not visually promoted as normal default workers in the front-door shell.

## What moved behind detail controls

The following are still available, but no longer compete with the main task surface by default:

- first-wave map details
- current memory context
- structured memory internals
- routing internals
- usage review log
- placeholder voice panel
- deeper status and telemetry

Advanced Mode remains the path for the full cockpit.

## Boundaries

This revamp does not add:

- autonomous agent execution
- destructive actions
- commit, tag, or push automation
- microphone or audio capture changes
- autoplay changes
- future-agent runtime work
- OpenClaw write access

Patch remains propose-only. Routing remains guidance, not automation.

## Success criteria

The front door is successful when a user can answer within a few seconds:

- Where do I type?
- Who gets this first?
- What should I do next?
- Where do I go for more detail?

