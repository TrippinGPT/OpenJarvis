# Relay First-Wave Chat Behavior

## Purpose

This note locks the expected live chat behavior after Simple Mode hands a task into `/chat`.

The goal is straightforward:

- keep the Simple Mode front door calm
- make the `/chat` answer feel like a real first-wave worker
- reduce generic assistant fallback
- keep first-wave scope explicit

## Active first-wave workers

Relay Simple Mode only hands normal work to these first-wave workers:

- Dispatch
- Recon
- Patch

Later-phase agents are intentionally out of the normal Simple Mode task path.

## Runtime model split

The current live handoff uses this model split:

- Dispatch -> `qwen3.5:9b`
- Recon -> `qwen3.5:9b`
- Patch -> `qwen2.5-coder:14b`

Simple Mode sets the selected model before the queued handoff is submitted into `/chat`.

If the exact Patch preference is not installed, the handoff now resolves to the closest available local coder lane before falling back to the current selected model. This keeps Patch from silently dropping back to a non-Patch path just because one exact model ID is missing.

## Handoff shape

Simple Mode now sends a structured first-wave handoff instead of only decorative routing text.

Each queued handoff includes:

- worker
- model
- first-wave scope reminder
- operator task
- strict worker instructions

This keeps the runtime path explicit and makes the `/chat` output more likely to stay inside the selected worker role.

## Output discipline by worker

### Dispatch

Dispatch is routing and coordination only.

Dispatch should:

- stay concise
- pick the owner clearly
- explain why in one short sentence
- give the next step in short form

Dispatch should not:

- answer like a generic assistant
- drift into broad analysis
- invent new teams or later-wave agents

Expected shape:

```text
Owner: <Dispatch | Recon | Patch>
Why: <one short sentence>
Next: <one short next step or 2-3 short ordered steps>
```

### Recon

Recon is evidence-first research and project-state work.

Recon should:

- use local repo, docs, config, scripts, and visible project context first
- stay grounded in what is actually present
- say what is known versus what is missing
- answer concisely

Recon should not:

- drift into Jira, GitHub activity, workplace/account context, or external recency summaries unless explicitly asked
- pretend missing evidence exists

Expected shape:

```text
Known:
Missing:
Answer:
```

### Patch

Patch is propose-only build, fix, script, and repo help.

Patch should:

- prefer the smallest safe fix first
- stay narrow unless broader rewrite is explicitly requested
- include files, validation, and risks
- stay explicit that the result is proposed, not already applied

Patch should not:

- imply files were already changed
- imply the work was already applied, committed, tagged, or pushed
- drift into destructive or auto-ship behavior

Expected shape:

```text
Proposed fix:
Files:
Validation:
Risks:
```

## Practical sanity checks

Use these checks after Simple Mode hands off into `/chat`.

### Dispatch check

Prompt:

```text
I am not sure whether this needs research or a code fix. Figure out who should handle it first.
```

Expected:

- Dispatch output stays short
- names Dispatch, Recon, or Patch as owner
- explains why briefly
- gives a short next step

### Recon check

Prompt:

```text
Summarize the current Relay fork state from the repo and docs.
```

Expected:

- Recon uses local repo/docs context first
- does not drift to Jira/GitHub/workplace context
- separates known vs missing vs answer cleanly

### Patch check

Prompt:

```text
Propose the smallest safe fix for a broken local Relay script flow and tell me how to validate it.
```

Expected:

- Patch stays propose-only
- names likely files
- includes validation
- does not imply anything was already changed or shipped

## What stays manual

The first-wave chat behavior does not authorize:

- destructive actions
- commit, tag, or push automation
- OpenClaw changes
- future-agent runtime work
- shell ownership changes

Patch remains propose-only even when the answer is strong.
