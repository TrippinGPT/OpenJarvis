# Relay Sarcastic Polish

This document tracks the current sarcastic-only polish lane for Kokoro `af_bella`.

## Purpose

- Tighten delivery for the strongest short-form Relay voice lane.
- Favor fast, sharp, command-center phrasing.
- Keep the output original, punchy, and usable for local TTS testing.

## Why sarcastic is the winning lane

- `af_bella` already sounds the most usable locally.
- `sarcastic` best matches the Relay / Smartmouth personality direction.
- `dry` and `command` are useful references, but they are not the current polish target.
- The goal now is delivery quality, not more model hunting.

## Active lane

- Voice: `af_bella`
- Mode: `sarcastic`
- Status: usable placeholder, polish next

## Evaluation criteria

- Clarity
- Speed
- Tone
- Bite
- Command-center feel
- Smartmouth delivery
- Relay fit

## Current test lines

- `Routing now. We have a plan. Try not to ruin it.`
- `Routing now. Don't screw it up.`
- `We have a plan. Miracles happen.`
- `Relax. I already fixed it.`

## Safety boundaries

- No autoplay.
- No microphone or audio capture.
- No app/runtime TTS integration.
- No OpenClaw changes.
- No new model downloads.
- No WAV/audio files should be committed.
