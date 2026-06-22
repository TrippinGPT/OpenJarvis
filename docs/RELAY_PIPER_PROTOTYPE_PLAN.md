# Relay Piper Prototype Plan

## Purpose

Piper is the first candidate for a future local/offline Relay voice prototype. This lane prepares a safe manual setup and test path without installing Piper, downloading a voice model, generating audio, or adding TTS runtime behavior.

## Current status

- **Prototype candidate:** Piper
- **Piper installation:** Not installed
- **Voice model:** Not selected or downloaded
- **Audio generation:** Not implemented
- **Audio playback:** Not implemented
- **Microphone or audio capture:** Not implemented
- **Automatic speech:** Disabled

## Why Piper first

- Piper is designed for local/offline speech generation.
- It offers a simpler first prototype path than more advanced TTS systems.
- It is suitable for validating the Relay voice workflow before considering larger dependency or model stacks.
- Kokoro remains a later candidate.
- Coqui/XTTS-style systems remain advanced, review-only candidates because of dependency, licensing, consent, and voice-cloning boundaries.

## Safety rules

- Use an original Relay voice only.
- Do not clone or imitate a real person.
- Do not impersonate a copyrighted character.
- Do not access a microphone or capture audio.
- Do not enable automatic speech without a clear user-controlled toggle.
- Keep future speech off by default.
- Review the selected Piper voice/model license before use.
- Do not claim Piper is installed or ready until the setup is completed and verified.

## Read-only setup check

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_setup.ps1
```

The checker reports local readiness only. It does not create folders, install software, download models, generate or play audio, access a microphone, call remote APIs, or modify OpenClaw.

The planned local paths are:

```text
D:\AI\TRIPPIN_AI_RELAY\tools\piper
D:\AI\TRIPPIN_AI_RELAY\outputs\tts_tests
```

These folders are not created by the checker. A missing result is expected before setup.

## Manual setup will be done only after user approval

A future approved setup task must document the exact Piper source, version, voice/model license, destination paths, and rollback steps before installation or download begins.

No command in this plan authorizes installation, download, model selection, audio generation, playback, or application integration.

## Proposed v1.10 first audio test

Only after explicit user approval, v1.10 may:

1. Install Piper manually or point Relay to an existing reviewed Piper installation.
2. Select one safe, licensed, original-sounding test voice/model.
3. Generate one original Relay test line from the approved voice profile.
4. Save the result under `outputs\tts_tests`.
5. Record the Piper version, model identity, license, command, and output filename.
6. Avoid auto-play unless the user explicitly approves playback.

The first test must not add microphone support, audio capture, voice cloning, automatic speech, browser shell execution, or OpenClaw integration.

## Related files

- [Relay TTS Plan](RELAY_TTS_PLAN.md)
- [Relay Personality Guide](RELAY_PERSONALITY_GUIDE.md)
- [Relay Script Pack](RELAY_SCRIPT_PACK.md)
- `config/relay_voice_profiles.json`
- `scripts/check_relay_tts_feasibility.ps1`
- `scripts/check_piper_setup.ps1`
