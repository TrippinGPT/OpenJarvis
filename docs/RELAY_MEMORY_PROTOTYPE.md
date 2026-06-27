# Relay Structured Memory Prototype

## Purpose

This is the first explicit Relay memory layer.

It exists to preserve useful operator continuity without turning Relay into a hidden long-term memory system.

This prototype comes before any Mem0 or heavier semantic memory layer.

## What this prototype stores

Relay stores a small local JSON snapshot in frontend local storage.

Current fields:

- `sessionId`
- `currentLane`
- `activeAgent`
- `currentObjective`
- `lastMeaningfulAction`
- `nextSuggestedMove`
- `recentStatusSummary`
- `pinnedNotes`
- `activeLanePriorities`
- `freezeNotes`
- `machineEnvironmentNotes`
- `currentBoundaries`
- `expiresAt`
- `clearedAt`
- `updatedAt`

After the v4.1.2 polish pass:

- the core continuity fields stay small and unchanged
- `sessionId`, `clearedAt`, and `updatedAt` remain in the model for hygiene and transparency
- those timing/session fields are now de-emphasized in the UI because they are support metadata, not the main operator context

## What it does not store

This prototype does not:

- store full raw chat history as memory
- scrape every UI action automatically
- sync across machines
- hide background memory behavior
- store microphone/audio data
- integrate Mem0

The goal is visible continuity, not invisible hoarding.

## Storage shape

- Storage location: browser local storage
- Storage key: `relay-structured-memory-v1`
- Scope: local browser profile on the current machine only

This keeps the prototype light and reversible.

## Transient vs pinned memory

### Transient memory

Transient fields are:

- `currentLane`
- `activeAgent`
- `currentObjective`
- `lastMeaningfulAction`
- `nextSuggestedMove`
- `recentStatusSummary`

These fields are intended to track the current working state, not permanent history.

### Pinned memory

Pinned notes are explicit operator-kept notes.

They remain visible until the operator removes them or clears all Relay memory.

### Workspace notes

Workspace notes stay visible as guardrails and context:

- lane priorities
- freeze notes
- machine/environment notes
- current boundaries

These are deliberately small and operator-visible.

## When Relay writes memory

The prototype writes memory only from known, explainable actions:

1. Chat request start

- updates lane
- updates current objective
- records that the operator sent a new request
- sets a next suggested move
- does not waste a write on a temporary "request started" status summary

2. Chat response completion

- records the last meaningful action
- updates the recent status summary
- refreshes the transient expiry window

3. Agent focus changes

- updates `activeAgent`
- records the current specialist in focus

4. Relay companion status refresh

- updates only the short status summary
- does not overwrite the current objective, active agent, or last meaningful task completion

5. Explicit pinned-note actions

- add note
- remove note
- clear transient memory
- clear all memory

## Expiry behavior

- Transient memory expires after 12 hours
- Expiry clears only transient continuity fields
- Pinned notes remain
- Workspace notes remain

After expiry, Relay shows that transient memory expired and keeps only the visible long-lived notes.

## Clear behavior

Two explicit hygiene controls exist in the Relay Companion memory panel.

### Reset transient

This clears:

- current lane
- active agent
- current objective
- last meaningful action
- next suggested move
- recent status summary

Pinned notes remain.

### Clear all

This clears:

- transient memory
- pinned notes

and resets the prototype to a fresh visible baseline with a new session ID.

## Where memory is surfaced

The current prototype is surfaced in:

- `/relay-popout`

The panel shows:

- current memory snapshot
- pinned notes
- workspace notes
- updated/expiry state
- clear/reset controls
- a short note describing what Relay is and is not tracking

## Why this comes before Mem0

Relay first needs to prove that a small explicit memory model is useful.

This prototype is intentionally:

- local-first
- operator-visible
- easy to clear
- easy to understand
- low dependency

If this shape proves useful, a later milestone can evaluate whether Mem0 should become a semantic or long-term layer on top of it.

## Practical usefulness review

### Clearly useful

- `currentLane`
- `activeAgent`
- `currentObjective`
- `lastMeaningfulAction`
- `nextSuggestedMove`
- `recentStatusSummary`
- `pinnedNotes`
- workspace note arrays

These are the fields that actually preserve operator continuity.

## How next-move guidance is derived

`nextSuggestedMove` is now derived by explicit rule logic instead of being rewritten as a hardcoded string on every UI action.

The current derivation uses:

- `currentLane`
- `activeAgent`
- `currentObjective`
- `recentStatusSummary`
- `pinnedNotes`
- workspace priorities when no stronger continuity signal exists

### Current rule order

1. backend/offline or fallback warnings
2. research lane with an active objective
3. conversation lane with objective and optional active agent
4. active agent plus objective
5. active agent only
6. objective only
7. pinned notes
8. workspace priorities
9. default cockpit fallback

### What this intentionally does not do

- no opaque AI reasoning
- no hidden summarizer
- no vector or graph lookup
- no transcript-level intent modeling

The guidance is meant to be short, explainable, and operator-auditable.

### Useful, but secondary

- `sessionId`
- `expiresAt`
- `clearedAt`
- `updatedAt`

These help hygiene and transparency, but they are support metadata rather than the main continuity payload.

### Fields intentionally not added

- transcript history memory
- hidden background summaries
- semantic/vector recall
- cross-session archive history
- cross-machine sync

### Expiry decision

The 12-hour transient expiry stays in place.

That is still the right first balance:

- long enough to survive a working block
- short enough to avoid silent forever-retention
- easy to explain in the UI

## Current recommendation

Use this prototype as the first continuity layer.

Only revisit Mem0 after Relay has real evidence that:

- these fields help operators
- explicit pin/clear/expire hygiene is working
- a semantic recall layer would solve a real next problem instead of adding unnecessary weight
