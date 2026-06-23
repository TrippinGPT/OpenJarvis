# Relay Piper Voice Comparison

## Purpose

This lane compares a small set of local Piper voices before any app integration. It is offline testing only and exists to help choose a better original Relay voice.

## Current baseline

- `en_US_lessac_medium` generated the first working local WAV.
- Lessac is a useful technical baseline.
- Lessac failed the Relay persona fit review and is not the final Relay voice.

## Comparison candidates

- `en_US_lessac_medium`
- `en_US_amy_medium`
- `en_US_ljspeech_medium`

## Scoring criteria

Review each candidate against:

- clarity
- speed
- robotic quality
- tone
- persona fit
- final decision

## Safety rules

- No autoplay.
- No app runtime TTS.
- No voice cloning.
- No real-person or copyrighted-character impersonation.
- Keep all model and WAV files local to the Relay repo and ignored by Git.

## How this lane is used

Run the gated comparison script to inspect selected voices, download only missing approved local pairs, and generate one comparison WAV per selected voice only when explicit allow flags are passed.

The output remains a local test artifact. It is not a runtime voice feature and it does not change OpenClaw.
