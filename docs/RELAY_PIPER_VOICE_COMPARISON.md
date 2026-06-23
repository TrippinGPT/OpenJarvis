# Relay Piper Voice Comparison

## Purpose

This lane compares a small set of local Piper voices before any app integration. It is offline testing only and exists to help choose a better original Relay voice.

## Current baseline

- `en_US_lessac_medium` generated the first working local WAV.
- Lessac is a useful technical baseline only.
- Lessac failed the Relay persona fit review and is not the final Relay voice.
- `en_US_amy_medium` is the best current candidate, but it is not final yet.
- Amy at length scale 0.85 was the strongest Amy variant so far, but it still is not final.
- `en_US_ljspeech_medium` is rejected.
- Danny is being tested next.

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

## Comparison outcome so far

- Lessac: technical baseline only
- Amy: best current candidate, but still needs tuning
- LJSpeech: rejected
- Danny: tested and rejected as robotic/unclear
- Kokoro feasibility: next planning lane after Piper fit failures

## Safety rules

- No autoplay.
- No app runtime TTS.
- No voice cloning.
- No real-person or copyrighted-character impersonation.
- Keep all model and WAV files local to the Relay repo and ignored by Git.

## How this lane is used

Run the gated comparison script to inspect selected voices, download only missing approved local pairs, and generate one comparison WAV per selected voice only when explicit allow flags are passed.

The output remains a local test artifact. It is not a runtime voice feature and it does not change OpenClaw.
