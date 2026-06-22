# Relay TTS Plan

## Purpose

This document defines a safe feasibility path for a future original Relay voice. It is planning only: no TTS engine, audio playback, microphone input, audio capture, voice cloning, model download, or automatic speech is implemented.

The Relay Popout HUD is the intended future voicebox surface. The main planned profile is Smartmouth Relay, publicly labeled Relay Companion or Relay Voice.

## Current status

- **Mode:** Planning only
- **TTS implementation:** Not implemented
- **Audio playback:** Not implemented
- **Microphone or audio capture:** Not implemented
- **Voice cloning:** Prohibited
- **Automatic speech:** Prohibited until a future user-controlled feature explicitly enables it
- **Default future behavior:** Off

## Identity and safety boundaries

- Relay voice must be original.
- Do not impersonate actors, public figures, private people, or copyrighted characters.
- Do not clone Deadpool, Ryan Reynolds, or any other identifiable person or character.
- Voice output must not expand permissions or bypass safety gates.
- Humor and delivery never override factual accuracy, risk disclosure, or approval requirements.
- Voice must not claim an action completed unless the action actually completed and was verified.
- Voice must not give investment advice, buy/sell recommendations, predictions, or guarantees.
- OpenClaw remains separate and read-only from Relay unless a future task explicitly changes that boundary.

## Main planned profile

### Smartmouth Relay

- **Public label:** Relay Companion or Relay Voice
- **Role:** Main cockpit voice
- **Direction:** Fast, sarcastic, funny, cocky-but-useful, fourth-wall-aware command-center energy
- **Delivery:** Concise, original, operationally clear, and honest about uncertainty
- **Source material:** [RELAY_PERSONALITY_GUIDE.md](RELAY_PERSONALITY_GUIDE.md) and [RELAY_SCRIPT_PACK.md](RELAY_SCRIPT_PACK.md)

The voice profile is a delivery specification, not a reference impression. Future implementation must select or build an original voice without copying a recognizable actor or character.

## Candidate local TTS options

### Piper

- Local/offline TTS candidate.
- Good first prototype candidate.
- Likely the simplest local voice lane.
- Requires voice selection, licensing review, Windows installation testing, and output-quality testing later.
- No voice or model should be downloaded without explicit approval.

### Kokoro

- Lightweight/open-weight TTS candidate.
- Potential quality and speed candidate.
- Requires Windows and OMEN hardware/software compatibility testing later.
- Requires package, model, license, and runtime review before installation.
- No voice or model should be downloaded without explicit approval.

### Coqui or XTTS-style systems

- Advanced candidate only.
- Requires careful licensing and dependency review.
- Requires an explicit no-cloning boundary.
- Must not clone real actors, copyrighted characters, public figures, private people, or anyone without valid rights and consent.
- Not recommended for the first Relay prototype.

### Cloud TTS

- Optional future lane only.
- Requires API keys, privacy review, data-retention review, cost review, and provider terms review.
- Not the first choice for local Relay.
- No credentials belong in this planning file or the voice-profile config.

## Recommended staged plan

### v1.7 — Planning, docs, and config only

- Define original voice identity and safety boundaries.
- Document candidate TTS lanes.
- Add planning-only voice-profile metadata.
- Do not install packages, download models, generate audio, or add UI controls.

### v1.8 — Local TTS feasibility checker

- Check supported Python version.
- Check audio-output availability without recording audio.
- Review candidate package documentation and licenses.
- Report Windows and OMEN compatibility constraints.
- Do not download models unless explicitly approved.
- Do not auto-install packages or modify system audio settings.

The v1.8 read-only checker is available at:

`scripts/check_relay_tts_feasibility.ps1`

Run it with:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_relay_tts_feasibility.ps1
```

The checker inventories local prerequisites only. It does not install packages, download models, generate or play audio, access a microphone, call remote APIs, or modify OpenClaw.

### v1.9 — Piper plan and read-only checklist

- Select Piper as the first local/offline prototype candidate.
- Document the manual setup, licensing review, safety rules, and proposed test paths.
- Add a read-only Piper setup checker.
- Do not install Piper, download models, create folders, generate audio, or add runtime integration.
- Keep Kokoro as a later candidate and Coqui/XTTS-style systems as advanced, review-only options.

See [RELAY_PIPER_PROTOTYPE_PLAN.md](RELAY_PIPER_PROTOTYPE_PLAN.md).

Run the read-only setup check with:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_setup.ps1
```

### v1.10 — First Piper audio test after explicit approval

- Install Piper manually or point to an existing reviewed installation.
- Select one safe, licensed test voice/model.
- Generate one original Relay test line.
- Save output under an explicitly approved test folder.
- Do not auto-play audio unless explicitly approved.
- Do not clone or imitate any identifiable person or character.
- Do not begin this stage without explicit user approval.

### v2.0 — Popout voice toggle

- Add a user-controlled voice toggle to the Relay Popout.
- Keep voice off by default.
- Speak only assistant responses or explicit test lines.
- Provide an immediate stop/mute control.
- Preserve all existing safety, truthfulness, privacy, and permission boundaries.

## Future implementation acceptance criteria

- User explicitly enables voice.
- Original voice identity is documented and reviewed.
- Candidate licenses and model terms are acceptable.
- No voice cloning or impersonation capability is used.
- Audio output can be stopped immediately.
- No microphone or recording permission is requested unless a separate future task explicitly authorizes it.
- Spoken content matches visible assistant content and verified system state.
- Failure to speak never changes or blocks text output.

## Related files

- [Relay Personality Guide](RELAY_PERSONALITY_GUIDE.md)
- [Relay Script Pack](RELAY_SCRIPT_PACK.md)
- [Relay Agent Roster](RELAY_AGENT_ROSTER.md)
- [Relay Piper Prototype Plan](RELAY_PIPER_PROTOTYPE_PLAN.md)
- `config/relay_voice_profiles.json`
