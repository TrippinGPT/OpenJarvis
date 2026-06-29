# OpenJarvis × Hermes Desktop × Relay Fork Plan

This document is the blueprint for the full forked product direction.

It is not a small tune-up plan. It defines what Trippin AI Relay should become when OpenJarvis is the implementation foundation, Hermes Desktop is the UX reference, and the Relay twist is the product behavior and operator model.

Authority for first-wave agent roles:

- [HERMES_JARVIS_AGENT_PLAN.md](HERMES_JARVIS_AGENT_PLAN.md)
- [HERMES_FIRST_WAVE_SETUP.md](HERMES_FIRST_WAVE_SETUP.md)

Related current-state references:

- [RELAY_CURRENT_STATE.md](RELAY_CURRENT_STATE.md)
- [RELAY_SIMPLE_MODE.md](RELAY_SIMPLE_MODE.md)
- [RELAY_MEMORY_PROTOTYPE.md](RELAY_MEMORY_PROTOTYPE.md)
- [RELAY_AGENT_ROSTER.md](RELAY_AGENT_ROSTER.md)

---

## 1. Fork identity

### What this product is trying to be

**Trippin AI Relay** is a local-first operator cockpit built on OpenJarvis.

It is not a generic chat app, not a cloud assistant, and not an autonomous AI operating system. It is a practical command center for one operator on one machine: clear task entry, visible state, honest handoffs, and a small first-wave specialist team.

The product sentence:

> OpenJarvis runs locally. Hermes Desktop keeps the shell simple. Relay keeps the operator oriented.

### What comes from OpenJarvis

OpenJarvis is the **implementation foundation**. Relay inherits:

- local LLM runtime and model routing through Ollama and OpenJarvis server
- FastAPI backend, React frontend, and desktop-capable shell
- agent, skill, channel, memory, telemetry, and connector primitives
- preset and config architecture under `configs/openjarvis/`
- CLI and launcher patterns (`jarvis serve`, stack scripts, doctor checks)
- research-grade evaluation and trace tooling as optional advanced surfaces

OpenJarvis supplies the engine room. Relay does not rewrite that room unless a product need clearly outgrows config and UI layering.

### What comes from Hermes Desktop inspiration

Hermes Desktop is the **UX reference**, not a separate repo to merge.

Borrow these patterns:

- calm, desktop-native simplicity over dashboard sprawl
- one obvious primary surface for the everyday task
- setup and readiness treated as first-class, not buried in settings
- local status, health, and preflight visible without opening five panels
- advanced tooling present but not default: memory browser, agents panel, traces, analytics, connectors

In Relay terms, Hermes is both a UX direction and a shell role:

- **Hermes shell** owns preflight, launcher readiness, local status, safe handoff, and logging
- **Hermes Desktop style** means the default UI should feel like a focused desktop companion, not a feature museum

Jarvis is the front-facing talk layer on top of that shell. Hermes keeps the room operational; Jarvis keeps the conversation readable.

### What the Relay twist adds

The Relay twist is the **product behavior, personality, and operator model**. It is what makes this fork worth maintaining separately from upstream OpenJarvis or from endless Hermes Desktop polish alone.

Relay adds:

| Relay principle | Meaning in product terms |
|---|---|
| Structured local memory | Small, explicit, operator-visible continuity instead of hidden long-term recall |
| Next-move guidance | Deterministic “what now” derived from visible memory, not vague assistant filler |
| Routing / handoff guidance | Named specialist recommendations with reasons; no fake autonomous team execution |
| Clear first-wave subagents | Dispatch, Recon, Patch only in v1 runtime scope |
| Simple mode first | Task-first cockpit defaults; depth on demand |
| Advanced mode second | Memory, routing detail, review, voice, telemetry behind an explicit toggle |
| Restart / control workflow | Stop, start, restart stack scripts; operator-visible readiness |
| Operator-visible state | Lane, objective, active agent, pinned notes, boundaries, and hygiene controls shown plainly |
| Practical workflow orientation | Research, build/fix planning, routing, and local readiness — not generic assistant fluff |

Relay personality stays sharp, controlled, and useful. Smartmouth tone is allowed in copy; autonomy theater is not.

### Final product definition

The fork target is:

**A local-first OpenJarvis-based desktop companion that defaults to Relay Simple Mode, exposes Hermes-style readiness and shell clarity, and uses a first-wave specialist team plus structured memory to keep the operator moving without pretending the product is already a full multi-agent OS.**

---

## 2. Product layers

Relay should be understood as six cooperating layers. Each layer has one job. Overlap is allowed in presentation; ownership must stay distinct.

```text
┌─────────────────────────────────────────────────────────────┐
│  Shell / UI layer                                           │
│  Relay Popout Simple Mode, dashboard, advanced panels     │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│  Talk / personality layer                                   │
│  Jarvis wrapper, Relay companion copy, specialist framing    │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│  Routing layer                                              │
│  Dispatch policy, visible handoff guidance, no auto-switch   │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│  Memory layer                                               │
│  Structured local snapshot, pins, expiry, clear/reset        │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│  First-wave agent layer                                     │
│  Hermes shell, Dispatch, Recon, Patch configs/prompts        │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│  Workflow / control layer                                   │
│  Stack scripts, restart flow, read-only bridge, manual gates │
└─────────────────────────────────────────────────────────────┘
```

### Shell / UI layer

**Job:** give the operator one trustworthy surface.

**Owns:**

- Relay Popout as primary companion surface
- Simple Mode default layout
- Advanced Mode access path
- dashboard and agents visualization as secondary command surfaces
- branded Relay shell over OpenJarvis frontend primitives

**Does not own:**

- routing policy logic duplicated invisibly in UI copy
- hidden memory behavior
- autonomous execution

### Talk / personality layer

**Job:** make system state readable and handoffs human.

**Owns:**

- Jarvis front-facing conversational wrapper
- Relay companion microcopy and specialist framing
- user-facing “what next” language
- per-agent identity presentation in `/agents` and popout quick guides

**Does not own:**

- Dispatch routing decisions
- Patch execution
- shell restart mechanics

### Routing layer

**Job:** recommend the best next specialist without pretending to orchestrate.

**Owns:**

- Dispatch role config and prompt
- deterministic routing guidance view in frontend
- handoff reason strings tied to structured memory
- dashboard route preview and agent focus context

**Does not own:**

- auto-switching agents at runtime
- background intent modeling
- second-wave agents in first-wave runtime

### Memory layer

**Job:** preserve useful continuity with visible hygiene.

**Owns:**

- structured local memory prototype (`relayMemory.ts`)
- transient vs pinned vs workspace note model
- 12-hour transient expiry
- next-move and routing guidance inputs
- explicit clear / reset controls

**Does not own:**

- full transcript archival as memory
- Mem0 or vector recall in first wave
- cross-machine sync

### First-wave agent layer

**Job:** provide three narrow specialists plus the Hermes shell role.

**Owns:**

- Hermes shell ownership
- Dispatch, Recon, Patch prompt/config layer
- model split documented in first-wave setup
- propose-only Patch boundary

**Does not own:**

- Redline, Veto, Racket runtime behavior in v1
- tool execution wiring
- commit/tag/push automation

### Workflow / control layer

**Job:** keep the local stack operable and safe.

**Owns:**

- `start_relay_stack.ps1`, `stop_relay_stack.ps1`, `restart_relay_stack.ps1`
- health checks and readiness reporting
- read-only OpenClaw bridge
- manual approval boundaries

**Does not own:**

- OpenClaw mutation
- destructive browser-triggered shell execution
- microphone/audio capture changes

---

## 3. First-wave implementation scope

This section locks what the fork builds first. Everything here is in scope for the initial product direction. Items marked **started** already exist in the repo and should be consolidated, not re-litigated.

### Locked first-wave deliverables

| Area | First-wave scope | Current status |
|---|---|---|
| Simple Mode shell | Default popout flow: one input, one recommended agent, one next action, Advanced toggle | **started** — see [RELAY_SIMPLE_MODE.md](RELAY_SIMPLE_MODE.md) |
| Advanced access path | Memory, routing detail, usage review, voice placeholder, extra status | **started** |
| Dispatch | Routing/coordination prompt, config, UI identity, guidance hooks | **started** |
| Recon | Research/summary prompt, config, UI identity | **started** |
| Patch | Propose-only build/fix prompt, config, UI identity | **started** |
| Structured local memory | Visible snapshot, pins, expiry, clear/reset | **started** — see [RELAY_MEMORY_PROTOTYPE.md](RELAY_MEMORY_PROTOTYPE.md) |
| Next-move guidance | Deterministic `nextSuggestedMove` from memory fields | **started** |
| Routing guidance | Deterministic recommended agent + stay/handoff reasoning | **started** |
| Restart / control flow | Stack stop/start/restart scripts, health-aware startup | **started** |
| Hermes shell role | Preflight/readiness/status ownership documented and config-backed | **started** |
| Jarvis talk layer | Front-facing wrapper prompt separate from Dispatch | **started** |
| First-wave model split | Hermes/Jarvis on `hermes3:8b`; Dispatch/Recon on `qwen3.5:9b`; Patch on `qwen2.5-coder:14b` | **started** |

### First-wave runtime rule

First-wave runtime means:

- config + prompt + UI + deterministic guidance
- not autonomous multi-agent execution
- not hidden tool wiring
- not second-wave specialists acting as live workers

The first three real operator paths remain:

1. summarize current project state
2. route an unclear task to the right helper
3. fix one real script or workflow issue in propose-only mode

### First-wave hard boundaries

These stay out of first-wave implementation even if UI nodes exist:

- destructive automation
- commit / tag / push automation
- microphone or audio capture changes
- autoplay changes beyond current gated placeholder behavior
- modifications to `D:\AI\OPENCLAW`
- `git add .` in any future automation guidance

---

## 4. What does NOT get built first

Defer these deliberately. Their presence in docs, dashboard art, or roster copy does not authorize first-wave runtime work.

| Deferred area | Why defer |
|---|---|
| Redline / Veto / Racket | Second-wave specialists; UI preview only for now |
| Full autonomous orchestration | Violates Relay’s operator-visible, manual-gated model |
| Giant analytics | OpenJarvis telemetry exists; Relay does not need a new analytics product inside v1 |
| Cross-machine sync | Infra-later; structured memory is local-browser scoped on purpose |
| Custom OS fantasy scope | Relay is a cockpit, not a platform rewrite |
| Every workflow lane at once | PaperLab, SlapDesk, Discord shell, and OpenClaw lanes stay documented but not product center |
| Mem0 / semantic memory foundation | Only after structured memory proves a real limit |
| Full per-agent runtime voice | Placeholder voice remains gated and manual |
| Real tool execution for specialists | Requires deliberate approval-gated design per agent |
| Upstream OpenJarvis merge cadence | Separate from product direction; review-based only |

---

## 5. UI direction

### Design intent

Combine:

- **Hermes Desktop-style simplicity** — one primary task surface, low visual noise, readiness first
- **Relay-style clarity** — operator guidance, visible state, no fake autonomy

The popout is the product heart. Dashboard and `/agents` are command-center satellites, not the default mental model.

### Simple Mode — shown by default

Show only what helps the next operator action:

- Relay companion header and core HUD
- plain-language task input
- current recommended specialist
- short reason the specialist fits
- one clear next suggested move
- compact agent quick guide
- explicit **Show advanced** affordance
- stack/health status only when it blocks progress

Simple Mode should answer, in order:

1. What am I doing?
2. Who should handle it?
3. What should I do next?

### Advanced Mode — hidden until requested

Expose depth without changing defaults:

- structured memory snapshot and pinned notes
- routing/handoff detail blocks
- usage review log and digest hints
- placeholder voice controls
- OpenClaw bridge status detail
- extra lane/workspace notes and hygiene metadata
- links out to dashboard and agents surfaces

Advanced Mode is an operator panel, not a settings junk drawer.

### Hermes-style patterns to borrow in the shell

| Pattern | Relay application |
|---|---|
| Primary chat/task surface | Popout input + response area |
| Readiness / doctor mindset | Hermes status and startup health surfaced succinctly |
| Desktop panels for power users | Advanced Mode instead of always-on dashboards |
| Setup clarity | Get Started and stack scripts remain visible paths |
| Restrained visual hierarchy | Reduce simultaneous panels in Simple Mode |

### Relay-style patterns to keep prominent

| Pattern | Relay application |
|---|---|
| Named specialist with reason | Recommended agent card |
| Visible memory | Transient objective, lane, pinned notes |
| Honest handoffs | Routing guidance without auto-switch |
| Manual control | Restart scripts, clear memory, no browser shell exec |
| Sharp controlled tone | Companion copy and agent framing |

### UI inheritance map

| Surface | Keep / reshape / defer |
|---|---|
| `/relay-popout` | **reshape** into canonical Simple/Advanced product shell |
| `/dashboard` | **keep** as secondary mesh and context surface |
| `/agents` | **keep** as identity and framing reference |
| OpenJarvis chat page | **defer** as default entry; not the Relay primary surface |
| Desktop analytics panels | **defer** behind Advanced or separate milestone |
| OpenJarvis setup wizard | **keep** for first-run; Relay stack scripts remain parallel path |

---

## 6. Architecture inheritance

### OpenJarvis pieces likely retained

| Component | Retain because |
|---|---|
| `src/openjarvis/server/` FastAPI app | Backend foundation already extended with Relay routes |
| Model routing and Ollama integration | Local-first core value |
| `configs/openjarvis/` preset and prompt system | First-wave agent configs already live here |
| Frontend React app infrastructure | Relay UI builds as a layer over it |
| Agent/skill/channel registries | Future safe wiring point |
| CLI / serve / doctor patterns | Operational baseline |
| Trace and eval tooling | Advanced-only; do not productize in v1 |

### OpenJarvis pieces likely replaced or re-skinned

| Component | Replace / re-skin because |
|---|---|
| Default landing UX | Relay Popout Simple Mode should become the primary experience |
| Generic chat-first information architecture | Relay is task-and-operator-first |
| Branding and product copy | Trippin AI Relay identity |
| Default visible panel set | Hide OpenJarvis dashboard complexity behind Advanced |
| Some desktop panels | MemoryBrowser/Energy/Savings are upstream concerns, not Relay v1 center |

### Hermes-style UX patterns to borrow

| Pattern | Borrow as |
|---|---|
| Thin operational shell | Hermes role + readiness summaries |
| Conversational front door | Jarvis talk wrapper |
| Advanced panels off the main path | Advanced Mode toggle |
| Local health visibility | Startup and health surfacing in popout |

### Relay components / patterns to reimplement or consolidate in the fork

These are Relay-native and should be treated as first-class fork assets, not temporary patches:

| Relay asset | Location / note |
|---|---|
| Structured memory model | `frontend/src/lib/relayMemory.ts` |
| Next-move derivation | `deriveRelayNextMoveView` |
| Routing guidance derivation | `deriveRelayRoutingGuidanceView` |
| Simple Mode shell | `frontend/src/pages/RelayPopoutPage.tsx` |
| Agent identity roster | `frontend/src/data/relayAgents.ts`, docs |
| Stack control scripts | `scripts/start_relay_stack.ps1`, etc. |
| First-wave config + prompts | `config/hermes_first_wave_agents.json`, `configs/openjarvis/prompts/relay_first_wave/` |
| Usage review log | `frontend/src/lib/relayUsageReview.ts` |
| Read-only OpenClaw bridge | backend bridge routes + dashboard status |

### Keep / replace / defer table

| Area | Keep | Replace / re-skin | Defer |
|---|---|---|---|
| OpenJarvis backend server | ✓ | | |
| Ollama model routing | ✓ | | |
| Relay popout shell | ✓ | reshape to canonical product entry | |
| OpenJarvis default chat home | | ✓ | |
| Structured memory prototype | ✓ | | |
| Deterministic guidance layer | ✓ | | |
| First-wave prompts/config | ✓ | | |
| Dashboard agent mesh | ✓ | | |
| Redline/Veto/Racket runtime | | | ✓ |
| Mem0 / semantic memory | | | ✓ |
| Full specialist tool execution | | | ✓ |
| OpenJarvis analytics dashboards | | | ✓ |
| Cross-machine sync | | | ✓ |
| OpenClaw write/integration | | | ✓ |
| Autonomous orchestration | | | ✓ |

---

## 7. Phased build order

Build in this order. Do not skip phase 1 documentation alignment before expanding runtime scope.

### Phase 1 — Blueprint and inheritance map

**Goal:** one agreed product direction.

Deliverables:

- this document
- updated handoff note in [RELAY_CURRENT_STATE.md](RELAY_CURRENT_STATE.md)
- confirm authority docs remain aligned

Exit criteria:

- team can answer keep/replace/defer for every major surface
- first-wave scope is locked

### Phase 2 — Simple Mode shell

**Goal:** make Relay Popout the obvious default product entry.

Deliverables:

- Simple Mode as default operator path
- Advanced toggle with no capability loss
- Hermes-style readiness/status copy in Simple surface
- reduced clutter and one clear next action

Exit criteria:

- a new operator can use Relay without opening dashboard first
- Simple Mode answers task / agent / next move

Status: **substantially started**; polish and consolidation continue here, not new scope sprawl.

### Phase 3 — First-wave agents

**Goal:** make Dispatch, Recon, Patch, Hermes, and Jarvis behave as distinct documented roles.

Deliverables:

- first-wave config and prompts wired consistently
- model split enforced in config docs and runtime selection path
- `/agents` framing matches runtime role boundaries
- Patch remains propose-only everywhere

Exit criteria:

- three test paths in [HERMES_FIRST_WAVE_SETUP.md](HERMES_FIRST_WAVE_SETUP.md) are reproducible
- Jarvis does not duplicate Dispatch logic

Status: **config/docs started**; runtime wiring depth remains Phase 3 work.

### Phase 4 — Memory / routing layer

**Goal:** operator continuity and handoffs feel intentional.

Deliverables:

- structured memory stable under status refresh
- next-move guidance deterministic and auditable
- routing guidance visible with stay/handoff reasons
- no auto-switching

Exit criteria:

- operator can inspect why Relay suggested a move or agent
- memory hygiene controls remain understandable

Status: **prototype live**; Phase 4 is consolidation and workflow proof, not new memory fields.

### Phase 5 — Advanced panels and controls

**Goal:** expose power without polluting Simple Mode.

Deliverables:

- Advanced memory/routing/review panels polished
- dashboard and agents remain secondary but coherent
- restart/control docs and UI hints aligned
- placeholder voice remains gated

Exit criteria:

- Advanced mode is useful to power users
- Simple mode remains clean after Advanced work lands

### Phase 6 — Evaluate later agents / workflow lanes

**Goal:** decide what earns runtime scope next.

Candidates:

- Redline for risk/scope review
- Veto for final review gate
- Racket for narrative scans
- PaperLab / SlapDesk workflow lanes
- safe tool wiring for first-wave agents
- semantic memory only if structured memory hits a proven wall

Exit criteria:

- evidence from real operator usage review and memory prototype
- explicit milestone before any second-wave runtime work

---

## 8. Success criteria

The fork is successful when it is **better than continuing to tune Hermes Desktop or Relay surfaces in isolation**.

### Operator outcomes

- a new session starts with an obvious task path in under one minute
- the operator always knows current objective, recommended agent, and next move
- memory feels helpful, visible, and easy to clear
- restart/recovery does not require manual process hunting
- handoffs read as recommendations, not fake autonomy

### Product outcomes

- Simple Mode stays the default without hiding real capability
- first-wave agents are distinct in docs, config, and UI framing
- Patch has never auto-executed or auto-shipped changes
- OpenClaw remains read-only from Relay
- no scope creep into second-wave agents without a new milestone

### Engineering outcomes

- OpenJarvis upgrades remain tractable because fork changes concentrate in Relay layer files
- deterministic guidance and memory remain testable without LLM nondeterminism
- stack scripts and docs remain the canonical control path

### Why this beats “just keep tuning Hermes Desktop”

Hermes Desktop tuning alone optimizes shell and conversation.

This fork optimizes the **operator loop**:

```text
task → visible state → recommended specialist → next move → manual control → clean restart
```

That loop is Relay-native. OpenJarvis supplies the engine. Hermes supplies the calm shell reference. Relay supplies the reason the fork exists.

---

## 9. Text architecture diagram

```text
Operator
   │
   ▼
Relay Popout (Simple Mode default)
   │
   ├─ Jarvis talk layer ────────────────┐
   ├─ Structured memory snapshot       │
   ├─ Next-move guidance               │
   ├─ Routing/handoff guidance         │
   └─ Advanced panels (on demand)      │
                                       │
OpenJarvis frontend / API ◄────────────┘
   │
   ├─ Chat / agent request path
   ├─ Relay voice placeholder routes
   ├─ OpenClaw bridge (read-only)
   └─ Health / model / settings APIs
           │
           ▼
OpenJarvis server + Ollama local models
   │
   ├─ hermes3:8b      → Hermes shell + Jarvis talk
   ├─ qwen3.5:9b      → Dispatch + Recon
   └─ qwen2.5-coder   → Patch (propose-only)

Workflow / control scripts (manual)
   ├─ start_relay_stack.ps1
   ├─ stop_relay_stack.ps1
   └─ restart_relay_stack.ps1
```

---

## 10. Why this fork is justified

Continuing only with:

- upstream OpenJarvis feature absorption, or
- Hermes Desktop visual polish, or
- Relay dashboard/agent cosmetic tuning

would leave the product without a coherent operator model.

The fork is justified because the combination is greater than the parts:

| Source | Unique contribution |
|---|---|
| OpenJarvis | credible local AI stack and extensibility |
| Hermes Desktop direction | calm shell and readiness-first desktop UX |
| Relay twist | operator guidance, structured memory, honest routing, manual control |

Without the fork plan, Relay risks becoming “OpenJarvis with a skin and a busy dashboard.”

With the fork plan, Relay becomes a **local operator product** with a disciplined first wave and a credible path for later specialists.

---

## 11. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Scope creep into second-wave agents | Lock first-wave roster; dashboard nodes are previews only |
| Hidden autonomy via routing UI | Keep routing guidance read-only; no auto-switch |
| Memory distrust | Stay operator-visible; keep clear/reset/expiry |
| OpenJarvis upstream drift | Concentrate fork changes in Relay layer files and docs |
| Re-implementing OpenJarvis dashboards | Defer analytics/energy/savings productization |
| Patch overreach | Propose-only prompt + manual execution boundary |
| OpenClaw contamination | Read-only bridge; hard rule against modifying `D:\AI\OPENCLAW` |
| Simple Mode regressions | Advanced toggle must preserve all existing capability |
| Voice lane distraction | Placeholder voice stays gated; no mic/autoplay expansion in fork v1 |

---

## 12. Validation checklist for this blueprint

Before starting a new implementation milestone, confirm:

- [ ] first-wave scope matches Section 3
- [ ] deferred items in Section 4 remain out of scope
- [ ] Simple Mode default is preserved
- [ ] structured memory stays visible and clearable
- [ ] routing guidance remains deterministic and non-autonomous
- [ ] Patch stays propose-only
- [ ] no OpenClaw write path introduced
- [ ] no destructive or commit/tag/push automation added
- [ ] phase order in Section 7 is respected

---

## 13. Suggested milestone tag for this blueprint

- Document milestone: `relay-v4.4-fork-plan`
- Branch: `relay-branding-v0`

This tag marks the product direction lock, not a runtime feature release.
