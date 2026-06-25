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

## Locked placeholder pack

The current placeholder order is now fixed for the project baseline:

- Winner: `relay_sarcastic_polish_04_20260624_154746.wav`
- Runner-up: `relay_sarcastic_polish_03_20260624_154746.wav`
- Backup: `relay_sarcastic_polish_02_20260624_154746.wav`

Default placeholder style:

- `Relax. I already fixed it.`

Secondary placeholder style:

- `We HAVE a plan. Miracles happen...`

Backup placeholder style:

- `Routing now. Don't screw it up...`

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

## Current status

- `af_bella` remains the active placeholder voice.
- `sarcastic` remains the active speaking mode.
- `sarcastic_polish_04` is the current default placeholder style.
- `sarcastic_polish_03` is the secondary style.
- `sarcastic_polish_02` is the backup style.
- This is still a placeholder pack, not the final production voice.
