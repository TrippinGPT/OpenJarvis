# Relay Piper Audio Review

## Purpose

Track subjective review results for local Relay voice tests without changing runtime behavior or approving a final voice too early.

## Reviewed test

- **Current reviewed file:** `D:\AI\TRIPPIN_AI_RELAY\outputs\tts_tests\relay_test_smartmouth_20260622_221740.wav`
- **Voice ID:** `en_US_lessac_medium`
- **Test line:** `Relay online. Try not to break anything expensive.`

## Review summary

- **Clarity:** 7/10
- **Speed:** acceptable
- **Robotic quality:** too robotic
- **Tone:** acceptable
- **Relay persona fit:** failed

## Decision

`en_US_lessac_medium` is a working technical baseline for the local Piper pipeline, but it is not approved as the final Relay Companion / Smartmouth Relay voice.

Across the comparison lane, Amy is the best current candidate, but it is not final yet. LJSpeech is rejected.
Amy at length scale 0.85 was the strongest Amy variant so far, but it still is not final.

## Next recommendation

v2.4.5 adds a Danny candidate gate before any app integration. Amy tuning remains useful, but Danny is now the next voice to test.

Related comparison plan: [RELAY_PIPER_VOICE_COMPARISON.md](RELAY_PIPER_VOICE_COMPARISON.md)
