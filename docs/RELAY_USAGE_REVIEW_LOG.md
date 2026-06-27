# Relay Usage Review Log

## Purpose

The Relay usage review log is a lightweight local-only operator feedback layer for the current cockpit build.

It exists to capture short practical reviews such as:

- what felt strong
- what felt mixed
- what felt rough
- what the cockpit made clear
- what the cockpit still made harder than it should

This is not hidden telemetry.

It is:

- local-only
- operator-visible
- manually written
- easy to clear

## Where the UI lives

The current UI lives in the Relay Popout Companion at:

- `/relay-popout`

The panel is labeled:

- `Usage Review Log`

It sits alongside the existing structured memory surface so the operator can log feedback against the visible current cockpit context.

## Review entry shape

Each entry stores:

- `tone`
  - `strong`
  - `mixed`
  - `rough`
- `area`
  - `popout`
  - `dashboard`
  - `agents`
  - `chat`
- `note`
- `createdAt`
- `currentLane`
- `activeAgent`
- `currentObjective`
- `nextSuggestedMove`
- `recentStatusSummary`
- `selectedModel`

## What context is captured

When the operator saves a review, Relay captures only the visible local cockpit context already present in the product.

That means:

- current lane
- active agent
- current objective
- next suggested move
- recent status summary
- selected model
- the operator's written note

This keeps the log explainable and useful without turning it into hidden behavior capture.

## Clear and reset behavior

The current controls are:

- `Save review`
  - saves a local entry
  - resets the review draft fields back to defaults after save
- per-entry remove
  - deletes one local review entry
- `Clear log`
  - clears the full local usage review log

The usage review log is separate from structured memory.

That means:

- clearing transient memory does not wipe the usage review log
- clearing the usage review log does not wipe structured memory
- both remain operator-controlled

## Boundaries

This feature does not:

- auto-send analytics
- capture hidden behavior
- sync across machines
- auto-score the operator
- auto-route agents
- modify OpenClaw

It is a local feedback notebook for the cockpit, nothing more.

## Practical use

Good review notes are short and specific, for example:

- `Strong: popout made the next step obvious without extra clicks.`
- `Mixed: current objective was clear, but the status text still felt noisy.`
- `Rough: I had to bounce between agents to figure out who owned the next step.`

The point is not sentiment tracking for its own sake.

The point is to keep a local record of what the cockpit is clarifying versus what still needs polish.
