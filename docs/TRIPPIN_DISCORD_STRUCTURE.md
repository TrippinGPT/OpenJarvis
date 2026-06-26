# Trippin AI Discord Structure

## Purpose

This document defines a clean Discord structure for the Trippin AI ecosystem.

It is meant to work as:

- the front door to the ecosystem
- the builder and dev onboarding point
- a project status board
- a clean home for active versus parked lanes
- a future community shell

This is a planning and organization doc only.

- No bot rollout is required here.
- No token or secret changes are required here.
- No OpenClaw changes are required here.

## Design goals

- Keep the front door legible in under five minutes.
- Make the active lane obvious.
- Separate builder work from public-facing chatter.
- Distinguish active, maintain, parked, and later lanes.
- Keep Discord usable even if setup is done manually first.

## Current lane judgment

Use this as the status logic behind the server layout.

### Active now

- Relay
- OpenClaw / SignalForge

### Maintain now

- Multi-agent Relay layer
- Read-only bridge/status surfaces
- Builder onboarding and project status

### Parked intentionally

- SlapDesk
- PaperLab

### Infra later

- production Discord bots
- deeper automation
- public community growth loops

## Recommended server roles

Keep roles simple at first.

- `@everyone`
  - default read access to welcome and public status areas
- `Core Builder`
  - active product and repo builders
- `Ops / Maintainer`
  - structure, incident, release, and channel upkeep
- `Project Lead`
  - final call on lane priority and direction
- `Observer`
  - read-only collaborator or early reviewer
- `Future Beta`
  - optional later public/community shell role, not needed immediately

## Channel naming convention

Use short, predictable names.

- info channels: `welcome`, `start-here`, `project-status`
- lane channels: `relay`, `openclaw-signalforge`, `slapdesk`, `paperlab`
- builder channels: `dev-onboarding`, `repo-map`, `active-work`
- ops channels: `incident-log`, `build-log`, `release-notes`
- parked/future channels: `parked-lanes`, `infra-later`

Avoid over-prefixing every channel with `trippin-`. The server name already provides that context.

## Recommended category and channel layout

### 1. START HERE

#### `welcome`

- Purpose: front-door explanation of what Trippin AI is
- For: everyone
- Belongs here:
  - one-paragraph ecosystem summary
  - what is active right now
  - where to go next
- Does not belong here:
  - repo-level build chatter
  - long roadmap threads

#### `start-here`

- Purpose: quick navigation and orientation
- For: new builders, collaborators, future community members
- Belongs here:
  - active lane list
  - server map
  - simple “if you are X, go here” instructions
- Does not belong here:
  - incident notes
  - long technical updates

#### `announcements`

- Purpose: high-signal updates only
- For: everyone
- Belongs here:
  - milestone completions
  - lane priority changes
  - builder onboarding updates
- Does not belong here:
  - back-and-forth discussion
  - debugging threads

### 2. PROJECT STATUS

#### `project-status`

- Purpose: visible source of truth for what is active, maintained, parked, and later
- For: everyone, especially new builders
- Belongs here:
  - active now list
  - maintain now list
  - parked intentionally list
  - next milestone notes
- Does not belong here:
  - deep implementation chatter

#### `release-notes`

- Purpose: product milestone and version tracking
- For: builders and observers
- Belongs here:
  - Relay milestone posts
  - major ecosystem changes
  - lane freeze or unfreeze notes
- Does not belong here:
  - raw bug reports

### 3. BUILDER ONBOARDING

#### `dev-onboarding`

- Purpose: first stop for a new builder
- For: builders and maintainers
- Belongs here:
  - what this ecosystem is
  - which repo matters first
  - current lane priority
  - boundaries and “do not touch” notes
- Does not belong here:
  - day-to-day sprint chatter

#### `repo-map`

- Purpose: explain which repos and lanes matter
- For: builders
- Belongs here:
  - Relay = active cockpit product lane
  - OpenClaw / SignalForge = backbone engine and intel/reporting layer
  - SlapDesk = real but parked
  - PaperLab = real but parked
- Does not belong here:
  - secret setup
  - raw credentials talk

#### `active-work`

- Purpose: current builder focus and handoff notes
- For: core builders
- Belongs here:
  - current work thread summaries
  - “working on now” notes
  - handoff links to docs or commits
- Does not belong here:
  - public announcement copy

### 4. RELAY

#### `relay`

- Purpose: primary product lane discussion
- For: builders and observers
- Belongs here:
  - dashboard, popout, agent layer, voice/UI status
  - current Relay direction
  - Relay-specific screenshots or notes
- Does not belong here:
  - engine internals that belong to OpenClaw

#### `relay-incidents`

- Purpose: Relay-specific break/fix notes
- For: builders and maintainers
- Belongs here:
  - startup issues
  - UI regressions
  - local runtime or validation failures
- Does not belong here:
  - general roadmap debate

### 5. OPENCLAW / SIGNALFORGE

#### `openclaw-signalforge`

- Purpose: engine, workflow, and intel/reporting lane discussion
- For: builders
- Belongs here:
  - backbone engine notes
  - reporting/intel architecture
  - read-only bridge relationship to Relay
- Does not belong here:
  - Relay UI polish threads

#### `bridge-boundaries`

- Purpose: preserve repo and permission boundaries
- For: builders and maintainers
- Belongs here:
  - “Relay cockpit, OpenClaw engine” reminders
  - what is read-only versus writable
  - lane separation notes
- Does not belong here:
  - feature brainstorming without boundary relevance

### 6. SLAPDESK

#### `slapdesk`

- Purpose: parked but real music/product lane
- For: maintainers and future builders
- Belongs here:
  - lane notes
  - next-entry conditions
  - links to docs when the lane resumes
- Does not belong here:
  - active Relay sprint chatter

### 7. PAPERLAB

#### `paperlab`

- Purpose: parked documentation/research lane
- For: maintainers and future builders
- Belongs here:
  - lane notes
  - next-entry conditions
  - later planning references
- Does not belong here:
  - active Relay execution work

### 8. INCIDENTS AND BUILD LOGS

#### `incident-log`

- Purpose: short incident capture
- For: builders and maintainers
- Belongs here:
  - what broke
  - impact
  - current state
  - link to fix thread or doc
- Does not belong here:
  - long live debugging transcripts

#### `build-log`

- Purpose: high-signal build or release checkpoints
- For: builders
- Belongs here:
  - major validation passes
  - notable launcher/build/runtime fixes
  - release-candidate notes
- Does not belong here:
  - every small local command output

### 9. FUTURE / PARKED

#### `parked-lanes`

- Purpose: make parked status explicit instead of forgotten
- For: builders and observers
- Belongs here:
  - why a lane is parked
  - what would reactivate it
  - what should not distract current work
- Does not belong here:
  - active execution threads

#### `infra-later`

- Purpose: hold future automation, bot, and community-shell ideas
- For: maintainers
- Belongs here:
  - Discord automation ideas
  - future bot rollout notes
  - future moderation or public-shell structure
- Does not belong here:
  - present-tense implementation without explicit approval

## New builder onboarding plan

### What this ecosystem is

Trippin AI is a multi-lane ecosystem with:

- Relay as the active cockpit/product shell
- OpenClaw / SignalForge as the backbone engine and intel/reporting layer
- additional lanes that are real, but not the immediate focus

### Which lane is most mature

- Relay is the strongest active product lane right now.

### Where a new builder should start

1. Read the current state doc
2. Read the Relay docs first
3. Understand the boundary: Relay stays separate from OpenClaw
4. Work in the active lane before touching parked lanes

### What is active right now

- Relay UI, command-center behavior, agent layer, launcher quality
- OpenClaw / SignalForge relationship and read-only bridge clarity
- ecosystem legibility and onboarding

### What is parked intentionally

- SlapDesk
- PaperLab
- broader Discord automation
- public community expansion work

### Which repos matter first

1. `D:\AI\TRIPPIN_AI_RELAY`
   - active front-end product shell
   - current best place for a new builder to contribute

2. `D:\AI\OPENCLAW`
   - backbone engine/workflow repo
   - understand the relationship, but do not modify casually

### Boundary notes for new builders

- Do not merge Relay and OpenClaw mentally or structurally.
- Relay is the cockpit.
- OpenClaw is the engine.
- Keep Discord structure aligned to that separation.
- Do not assume parked lanes are abandoned; they are just not priority now.

## Suggested pinned-message content

### `welcome` pin

> Trippin AI is a multi-lane ecosystem. Relay is the active cockpit. OpenClaw / SignalForge is the backbone engine. Start in `start-here` if you want the map, or `dev-onboarding` if you are here to build.

### `project-status` pin

> Active now: Relay, OpenClaw / SignalForge clarity, onboarding.  
> Maintain now: multi-agent layer, bridge/status surfaces.  
> Parked intentionally: SlapDesk, PaperLab.  
> Infra later: bots, public shell automation, deeper community structure.

### `dev-onboarding` pin

> Start with Relay. Read the current-state and lane docs. Understand the Relay/OpenClaw boundary before touching anything else. If you are unsure where work belongs, ask in `active-work`.

## Suggested onboarding checklist

- Read `welcome`
- Read `start-here`
- Read `project-status`
- Read `dev-onboarding`
- Read `D:\AI\TRIPPIN_AI_RELAY\docs\RELAY_CURRENT_STATE.md`
- Understand Relay vs OpenClaw separation
- Confirm active lane before starting work
- Avoid parked lanes unless explicitly reactivated

## Manual setup order

If setting the server up manually, create categories in this order:

1. START HERE
2. PROJECT STATUS
3. BUILDER ONBOARDING
4. RELAY
5. OPENCLAW / SIGNALFORGE
6. SLAPDESK
7. PAPERLAB
8. INCIDENTS AND BUILD LOGS
9. FUTURE / PARKED

This order keeps the front door clear and makes current priority visible before lane depth.

## Recommended first-use principle

If a new person joins and can only read three channels, they should still understand:

- what Trippin AI is
- that Relay is the active product lane
- that OpenClaw is separate backbone infrastructure
- which lanes are parked on purpose

If the server layout fails that test, it is too noisy.
