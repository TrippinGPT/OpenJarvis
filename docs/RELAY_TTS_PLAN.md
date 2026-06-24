# Relay TTS Plan

## Purpose

This document defines a safe feasibility path for a future original Relay voice. It is planning only: no TTS engine, audio playback, microphone input, audio capture, voice cloning, model download, or automatic speech is implemented.

The Relay Popout HUD is the intended future voicebox surface. The main planned profile is Smartmouth Relay, publicly labeled Relay Companion or Relay Voice.

## Current status

- **Mode:** Planning only
- **Piper package:** Installed locally only in `tools\piper.venv`
- **Piper runtime:** Python 3.11.15 / `piper-tts` 1.4.2
- **Piper review result:** technical pipeline works, but the tested voices did not reach the final Relay Companion fit
- **Next TTS lane:** Kokoro voice/style comparison sweep after the first WAV baseline
- **Kokoro runtime target:** uv-managed CPython 3.11.15, not default Python 3.14.5
- **Kokoro status:** gated venv setup completed; first WAV test has been run locally and the comparison sweep lane is ready
- **Kokoro sweep runner:** accepts `-PythonExe` and defaults to the Kokoro venv Python
- **Current delivery focus:** `af_bella` with sarcastic-only polish
- **Voice-model gate:** `config\piper_voice_models.json`
- **Application TTS integration:** Not implemented
- **Audio playback:** Not implemented
- **Microphone or audio capture:** Not implemented
- **Voice cloning:** Prohibited
- **Automatic speech:** Prohibited until a future user-controlled feature explicitly enables it
- **Default future behavior:** Off
- **Local offline test WAV generation:** Gated
- **Relay Popout voice toggle:** Future work
- **Final voice selection:** Not decided

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

### v2.0 — Piper sandbox folders only

- Prepare `tools\piper` and `outputs\tts_tests` inside the Relay repository.
- Add README boundary notes to both sandbox folders.
- Provide a constrained preparation script that creates only those folders and missing README files.
- Do not install Piper, download binaries or models, generate audio, or add runtime integration.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\prepare_piper_sandbox.ps1
```

### v2.1 — Gated Piper scripts only

- Add dry-run-first install and test-line runner scripts.
- Keep `-AllowInstall` as a manual-only placeholder until a compatible local Python lane is approved.
- Require `-AllowGenerate`, an existing Relay-local Piper module, and a manually supplied reviewed voice model before any test output.
- Do not download voice models automatically.
- Do not auto-play audio.
- Do not add microphone input, audio capture, voice cloning, browser shell execution, or Popout runtime integration.

The maintained candidate lane is `piper-tts` from [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl). No Piper package or model is installed by v2.1 validation.

### v2.1.1 — Python runtime compatibility check

- Inventory the default Python and Windows Python launcher runtimes.
- Prefer Python 3.11 for a future Relay-local Piper venv.
- Accept Python 3.12 when 3.11 is unavailable.
- Treat Python 3.13/3.14-only systems cautiously until Piper compatibility is confirmed.
- Keep installation disabled and do not create a virtual environment.
- Do not add Piper runtime or Relay Popout voice integration.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_python_runtime.ps1
```

### v2.2 — Isolated local Piper install

- Create `tools\piper.venv` with the approved Python 3.11.15 runtime.
- Install pinned `piper-tts` 1.4.2 inside that venv only.
- Keep global Python and global site packages unchanged.
- Ignore the complete venv from Git.
- Do not download a voice model.
- Do not generate or play audio.
- Do not add Relay Popout runtime integration or a voice toggle.

### v2.3 - Approved Piper voice-model selection and gated download

- Define the approved local test voice in `config\piper_voice_models.json`.
- Gate the download through `scripts/download_piper_voice_model_gated.ps1`.
- Keep voice files under `tools\piper\voices` and ignored by Git.
- Require license and model-card review before any distribution discussion.
- Do not add application runtime integration or audio generation yet.

The approved local voice candidate is `en_US_lessac_medium` from the `rhasspy/piper-voices` repository. The selected voice pair lives only under `tools\piper\voices` and remains separate from `tools\piper.venv`.

### v2.4 - First gated local test WAV

- Generate one local Relay test WAV only when `-AllowGenerate` is passed to `scripts/run_piper_test_line_gated.ps1`.
- Use the approved voice pair under `tools\piper\voices`.
- Keep the output inside `outputs\tts_tests` and leave it ignored by Git.
- Do not autoplay the result.
- Do not add application runtime TTS integration yet.

The first WAV validates the local Piper path only. Popout voice toggle work remains future implementation.

### v2.4.1 - Audio review result

- Local generation works and the Piper pipeline is useful.
- `en_US_lessac_medium` is a working technical baseline, but it is not approved as the final Relay voice.
- The popout voice toggle remains blocked until a better Relay voice is approved.

### v2.4.2 - Comparison lane

- The first voice failed final fit review.
- Comparison testing is next.
- Compare the baseline against additional local Piper candidates before any application integration.

### v2.4.3 - Amy tuning before app integration

- Amy is the best current candidate.
- LJSpeech is rejected.
- Lessac remains only a technical baseline.
- Tune Amy locally before any Relay app integration or voice-toggle work.

### v2.4.5 - Danny candidate gate

- Test Danny next as a possible better Piper candidate.
- Keep runtime/app TTS blocked until a voice is approved.
- Danny was tested and rejected as robotic/unclear.
- If Piper voices fail, Kokoro remains the next planning/checking lane.

### v2.5 - Kokoro feasibility lane

- Evaluate Kokoro 82M as the next local/offline TTS candidate after the Piper fit failures.
- Keep the lane planning-only until an explicit install approval is given.
- Do not add app runtime TTS, autoplay, microphone access, or voice cloning.
- Use the official Kokoro GitHub repository and official model page as the primary references.

### v2.5.1 - Kokoro prerequisite prep

- Python 3.11.15 is preferred for the future Kokoro setup.
- The machine currently defaults to Python 3.14.5, so the default interpreter is not the target.
- The uv-managed CPython 3.11.15 runtime is the correct local target.
- `espeak-ng` is now verified and ready.
- This stage documented prerequisites and checks readiness.
- Do not install Kokoro yet without the gated setup flag.

### v2.5.2 - Kokoro gated venv setup

- The gated Kokoro venv setup lane is complete.
- `scripts/setup_kokoro_venv_gated.ps1` is dry-run by default.
- `-AllowSetup` is required to create `tools\kokoro.venv`.
- `-SkipPackageInstall` allows a venv-only setup with pip upgrade only.
- No audio generation yet.
- No app/runtime TTS yet.
- No microphone or audio capture.

### v2.5.3 - First gated Kokoro WAV test

- Generate the first Kokoro WAV only when `-AllowGenerate` is passed to the gated runner.
- Use `-AllowModelDownload` when the Kokoro cache needs to be prefetched locally.
- Keep cached assets under `tools\kokoro\models`.
- Keep generated WAV output under `outputs\tts_tests`.
- Use `af_heart` as the baseline Kokoro voice for the first local test.
- Use the Smartmouth Relay planning line as the first local Kokoro line.
- Do not add application runtime TTS or a voice toggle yet.
- The generated WAV remains local and ignored by Git.

### v2.5.4 - Kokoro voice/style comparison sweep

- Compare several official Kokoro voices against several Smartmouth Relay lines.
- Keep the comparison sweep local, gated, and ignored by Git.
- Use the first WAV as the baseline reference.
- The sweep runner is `scripts/run_kokoro_voice_sweep_gated.ps1`.
- The sweep doc is `docs/RELAY_KOKORO_VOICE_SWEEP.md`.
- No application/runtime TTS, autoplay, microphone access, or voice cloning.

### v2.5.4.1 - Kokoro sweep runner fix

- The sweep runner now accepts `-PythonExe`.
- The default interpreter is `tools\kokoro.venv\Scripts\python.exe`.
- The runner validates the venv Python directly before generating anything.

### v2.5.9 - Sarcastic polish lane

- Lock the current delivery target to `af_bella`.
- Use `sarcastic` as the active polish mode.
- Keep `dry` and `command` available but not as the current quality target.
- Focus on short, sharp, original Relay delivery.
- Use the sarcastic polish runner for the strongest short-form comparison.

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
- [Relay Piper Voice Model Selection](RELAY_PIPER_VOICE_MODEL_SELECTION.md)
- `config/relay_voice_profiles.json`
- `config/piper_voice_models.json`
- `scripts/prepare_piper_sandbox.ps1`
- `scripts/install_piper_gated.ps1`
- `scripts/run_piper_test_line_gated.ps1`
- `scripts/download_piper_voice_model_gated.ps1`
- `scripts/check_piper_python_runtime.ps1`
- [Relay Piper Voice Comparison](RELAY_PIPER_VOICE_COMPARISON.md)
- `scripts/run_piper_voice_comparison_gated.ps1`
- [Relay Piper Amy Tuning](RELAY_PIPER_AMY_TUNING.md)
- `scripts/run_piper_amy_tuning_gated.ps1`
- [Relay Piper Danny Test](RELAY_PIPER_DANNY_TEST.md)
- `scripts/run_piper_danny_test_gated.ps1`
- [Relay Kokoro TTS Plan](RELAY_KOKORO_TTS_PLAN.md)
- `scripts/check_kokoro_feasibility.ps1`
- [Relay Kokoro Prerequisites](RELAY_KOKORO_PREREQUISITES.md)
- `scripts/check_kokoro_prereqs.ps1`
- [Relay Kokoro Venv Setup](RELAY_KOKORO_VENV_SETUP.md)
- `scripts/setup_kokoro_venv_gated.ps1`
- [Relay Kokoro First WAV Test](RELAY_KOKORO_FIRST_WAV_TEST.md)
- `scripts/run_kokoro_first_wav_gated.ps1`
- [Relay Kokoro Voice/Style Sweep](RELAY_KOKORO_VOICE_SWEEP.md)
- `scripts/run_kokoro_voice_sweep_gated.ps1`
