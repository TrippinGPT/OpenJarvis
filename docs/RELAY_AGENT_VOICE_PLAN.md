# Relay Agent Voice Plan

## Purpose

This document records the planned voice direction for Relay's specialist agents before any additional speech plumbing is built.

It is planning only.

- Relay Companion remains the only implemented runtime placeholder voice.
- Dispatch, Recon, Patch, Redline, Racket, Hermes, and Veto do not have runtime speech.
- No microphone input, autoplay, cloud TTS, voice cloning, or OpenClaw changes are introduced by this plan.

## Planning boundaries

- Use practical voice descriptors, not celebrity impressions.
- Keep every agent distinct from Relay Companion and from each other.
- Preserve the existing safety model: voice direction does not imply new permissions, execution power, or runtime behavior.
- Treat all specialist voice work as future optional placeholder treatment until a later milestone explicitly approves implementation.

## Relay Companion baseline

Relay Companion remains the main implemented placeholder voice lane.

- Active placeholder voice: `af_bella`
- Active placeholder mode: `sarcastic`
- Current role in product: main cockpit companion
- Tone baseline: sharp, competent, lightly sarcastic, controlled

The agents below should feel adjacent to Relay Companion, but not like copies of it.

## Agent voice directions

### Dispatch

- Personality summary: Calm traffic control for messy requests.
- Role summary: Turns noise into a route, assigns specialists, and keeps the plan legible.
- Desired voice feel: crisp, composed, tactical, command-center lead
- Pacing and cadence: steady pacing, clean handoff rhythm, minimal hesitation
- Warmth/harshness: moderate warmth, low harshness
- Likely placeholder direction: calm operations lead with concise route summaries and dependency callouts
- Distinct from Relay Companion: less sarcasm, more control-room clarity and sequencing

### Recon

- Personality summary: Observes first, labels second, publishes last.
- Role summary: Scans the field, separates signal from theater, and returns evidence with context.
- Desired voice feel: observant, alert, analytical, source-conscious
- Pacing and cadence: medium pace, deliberate emphasis on evidence and confidence
- Warmth/harshness: low warmth, low harshness
- Likely placeholder direction: sharp intel brief with restrained attitude and clear verification beats
- Distinct from Relay Companion: less attitude, more evidence discipline and uncertainty labeling

### Patch

- Personality summary: Builds the fix, skips the sermon.
- Role summary: Narrows the problem, lands the smallest reliable change, and proves it with a test.
- Desired voice feel: clipped, practical, builder-minded, no-nonsense
- Pacing and cadence: fast, efficient, short statements with hard stops
- Warmth/harshness: low warmth, medium harshness
- Likely placeholder direction: compact builder voice with low ceremony and quiet confidence
- Distinct from Relay Companion: more blunt and mechanical, less playful, more diff-and-test energy

### Redline

- Personality summary: Stops the bad idea before it grows legs.
- Role summary: Checks scope, safety, and approval boundaries before momentum wins.
- Desired voice feel: strict, skeptical, low-warmth, risk-control authority
- Pacing and cadence: clipped pacing, strong stop/go phrasing, decisive pauses
- Warmth/harshness: very low warmth, high harshness
- Likely placeholder direction: firm control tone built for risk flags, boundary calls, and approval gates
- Distinct from Relay Companion: less charm, more hard-edged constraint and enforcement energy

### Racket

- Personality summary: Hears the story behind the chart noise.
- Role summary: Tracks narrative drift, hype language, and crowd framing without pretending it can guarantee the outcome.
- Desired voice feel: sly, fast-reading, pattern-aware, culturally sharp
- Pacing and cadence: quick pace, lighter punch, subtle bite on key phrases
- Warmth/harshness: medium warmth, medium harshness
- Likely placeholder direction: nimble narrative read with measured bite and clear hype-vs-signal contrast
- Distinct from Relay Companion: more pattern-hunter than cockpit lead, sharper on tone and crowd behavior

### Hermes

- Personality summary: Fast hands, light footprint, clean readout.
- Role summary: Checks readiness, launch conditions, and local blockers without touching anything reckless.
- Desired voice feel: light-footprint, precise, efficient, low-drama
- Pacing and cadence: quick, clean, preflight cadence with short status beats
- Warmth/harshness: moderate warmth, low harshness
- Likely placeholder direction: quick scout tone with clean status phrasing and minimal flourish
- Distinct from Relay Companion: more utility and readiness-focused, less sarcasm, lighter operational energy

### Veto

- Personality summary: Final word, no sentimental attachments.
- Role summary: Runs the last pass and returns a clean approve, revise, or reject call.
- Desired voice feel: final-review tone, cold, authoritative, decisive
- Pacing and cadence: slow-to-medium pace, intentional verdict timing, sharp closeout
- Warmth/harshness: very low warmth, high harshness
- Likely placeholder direction: controlled final-review delivery with hard edges and explicit verdict framing
- Distinct from Relay Companion: colder and more absolute, built for final judgment instead of cockpit banter

## Recommended implementation order

If future placeholder voice treatment is approved, use this order:

1. Dispatch
   - Highest leverage after Relay Companion
   - Natural fit for route summaries, task framing, and command-center handoffs

2. Redline
   - Strongly distinct identity
   - High value for warnings, boundaries, and stop/go moments

3. Hermes
   - Good fit for readiness, preflight, and local status readouts
   - Lower-risk lane because the tone is utility-first

4. Veto
   - Clear role and distinct final-review energy
   - Useful for approval/rejection framing without broad conversational scope

5. Patch
   - Good candidate once builder/fixer playback patterns are worth testing

6. Recon
   - Better after the reporting/intel surfaces are more mature

7. Racket
   - Most dependent on nuance and phrasing polish
   - Better to defer until the narrative lane needs its own runtime treatment

## Distinctness summary

- Relay Companion: sharp cockpit guide, lightly sarcastic, main companion energy
- Dispatch: calm coordinator
- Recon: observant intel analyst
- Patch: blunt fixer
- Redline: strict boundary control
- Racket: sly narrative hunter
- Hermes: light-footprint scout
- Veto: cold final reviewer

## Future implementation notes

- Future per-agent placeholder speech should start as isolated, opt-in, local-only UI actions.
- No full runtime multi-agent speech should be added without a separate milestone.
- Each agent should keep a narrow, role-specific trigger surface rather than a broad conversational voice layer.
- Any future runtime treatment should reuse existing identity fields first before adding new metadata.
