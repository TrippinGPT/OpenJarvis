# Relay Agent Roster

Trippin AI Relay is the cockpit and routing switchboard. OpenClaw Core remains the separate engine.

Relay agents are specialist roles, not autonomous live actors. The current implementation supports context, visualization, routing previews, and safe planning. Execution and tool wiring are future work and must be deliberately designed, reviewed, and approval-gated.

Personality and reusable writing references:

- [Relay Personality Guide](RELAY_PERSONALITY_GUIDE.md)
- [Relay Script Pack](RELAY_SCRIPT_PACK.md)

## Dispatch

- **Role:** Coordinator
- **Purpose:** Routes requests and coordinates specialist agents.
- **Best for:** Planning, triage, task breakdown, and routing decisions.
- **Boundary:** Coordination only. No destructive actions.
- **Future safe actions:** Create a routing plan, copy a task brief, or open the relevant page.

## Recon

- **Role:** Research Intel
- **Purpose:** Scans sources, gathers context, and supports research/reporting.
- **Best for:** Source gathering, summaries, market or intelligence scans, and context packs.
- **Boundary:** Research only. Verify sources before publishing.
- **Future safe actions:** Create a research brief, list source targets, or open bridge status.

## Patch

- **Role:** Engineering
- **Purpose:** Build, fix, test, and repo workflow support.
- **Best for:** Codex tasks, code patches, build checks, and script planning.
- **Boundary:** No destructive file operations without explicit approval.
- **Future safe actions:** Copy a Codex task, run an approved read-only status check, or draft a patch plan.

## Redline

- **Role:** Risk Analyst
- **Purpose:** Checks safety, scope, boundaries, and operational risk.
- **Best for:** Risk review, scope control, compliance boundaries, and paper/live separation.
- **Boundary:** Does not approve live financial actions.
- **Future safe actions:** Create a risk checklist, review a planned task, or flag unsafe scope.

## Racket

- **Role:** Narrative Hunter
- **Purpose:** Tracks hype, trend language, narrative shifts, and signal patterns.
- **Best for:** Trend language, hype or trap labels, content angles, and narrative reports.
- **Boundary:** Reporting only. No predictions or guaranteed outcomes.
- **Future safe actions:** Create a narrative scan prompt, copy trend labels, or draft a report angle.

## Hermes

- **Role:** Local Scout
- **Purpose:** Local preflight, readiness checks, launcher/logging support.
- **Best for:** Local checks, readiness summaries, incident or build logging, and workspace launch support.
- **Boundary:** No registry edits, overclocking, risky service changes, or destructive cleanup.
- **Future safe actions:** Run approved read-only checks, create an incident log draft, or open launcher docs.

## Veto

- **Role:** Review Gate
- **Purpose:** Final review, cleanup, approval/rejection, and incident quality control.
- **Best for:** Final passes, cleanup notes, publish review, and approve or reject drafts.
- **Boundary:** Review only unless the user explicitly approves the next action.
- **Future safe actions:** Create a review checklist, copy an approval note, or flag missing requirements.

## Current implementation status

- Dashboard route preview: implemented
- Clickable dashboard agents: implemented
- Agents tab selected context: implemented
- Real execution: not implemented
- Tool mapping: not implemented
- Voice/TTS: not implemented
- OpenClaw bridge: read-only

## Main personality direction

Smartmouth Relay is the internal direction for Relay's original command-center personality. Public UI labels remain Relay Companion or Relay Voice. See the [Relay Personality Guide](RELAY_PERSONALITY_GUIDE.md) for the full style and safety rules.

This personality pass is text planning only. TTS, microphone input, audio capture, and voice generation are not implemented.

## Future execution rules

- No arbitrary shell execution.
- No destructive actions without explicit approval.
- OpenClaw remains separate from the Relay repository.
- PaperForge remains fake money only.
- Market and intelligence lanes remain research/reporting only.
- Any live action must be deliberately designed, reviewed, and approval-gated.
