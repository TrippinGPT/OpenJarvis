# Relay Piper Prototype Plan

## Purpose

Piper is the first candidate for a future local/offline Relay voice prototype. This lane prepares a safe manual setup and test path without installing Piper, downloading a voice model, generating audio, or adding TTS runtime behavior.

## Current status

- **Prototype candidate:** Piper
- **Piper installation:** Installed locally in `tools\piper.venv`
- **Piper package:** `piper-tts` 1.4.2
- **Piper Python:** 3.11.15
- **Voice model candidate:** `en_US_lessac_medium`
- **Voice-model gate:** Defined in `config\piper_voice_models.json`
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

## v2.0 Piper sandbox preparation

v2.0 prepares the two Relay-local sandbox folders and their boundary README files:

```text
D:\AI\TRIPPIN_AI_RELAY\tools\piper
D:\AI\TRIPPIN_AI_RELAY\outputs\tts_tests
```

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\prepare_piper_sandbox.ps1
```

The preparation script is restricted to those paths inside the Relay repository. It creates the folders and `README.md` files only when missing. It does not install Piper, download binaries or models, generate or play audio, access a microphone, call remote APIs, or modify OpenClaw.

Actual Piper installation, voice-model selection, and the first audio test still require explicit user approval in a future task.

## Manual setup will be done only after user approval

A future approved setup task must document the exact Piper source, version, voice/model license, destination paths, and rollback steps before installation or download begins.

No command in this plan authorizes installation, download, model selection, audio generation, playback, or application integration.

## v2.1 gated install and test-line scripts

v2.1 adds two dry-run-first scripts:

```text
scripts/install_piper_gated.ps1
scripts/run_piper_test_line_gated.ps1
```

Both scripts default to dry-run mode.

- `-AllowInstall` displays an approval banner and manual setup steps, but v2.1 intentionally remains a no-install placeholder.
- The current reviewed package lane is `piper-tts` from [OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl).
- The machine currently reports Python 3.14 while the reviewed package metadata explicitly lists support through Python 3.13, so no install command is guessed or executed.
- `-AllowGenerate` can generate only when a Relay-local Piper module and exactly one manually supplied ONNX voice model/config are already present.
- The runner never downloads a model and never auto-plays output.
- No script accesses a microphone, captures audio, clones a voice, impersonates a real person or copyrighted character, executes browser shell commands, or modifies OpenClaw.

Dry runs:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\install_piper_gated.ps1
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1
```

Manual approval gates:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\install_piper_gated.ps1 -AllowInstall
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\run_piper_test_line_gated.ps1 -AllowGenerate
```

The first approved model must be original-sounding, license-reviewed, and placed manually under `tools\piper\voices`. Actual Popout integration and automatic speech remain unimplemented.

## v2.1.1 Python runtime compatibility

v2.1.1 adds a read-only Python runtime inventory before any Piper installation:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\check_piper_python_runtime.ps1
```

The current default runtime is Python 3.14.5. The Windows launcher also reports Python 3.12 and a uv-managed CPython 3.11.15. Piper installation remains disabled until a later task explicitly selects and verifies the Relay-local runtime.

Runtime preference:

1. Python 3.11 in a Relay-local venv
2. Python 3.12 in a Relay-local venv
3. Python 3.13 or 3.14 only with additional compatibility review

The compatibility checker identified the available uv-managed Python 3.11 runtime as preferred. v2.2 subsequently approved that runtime for `D:\AI\TRIPPIN_AI_RELAY\tools\piper.venv`. The checker itself remains read-only and never creates a venv, installs packages, downloads models, or generates audio.

## v2.2 isolated local Piper install

v2.2 used the approved Python 3.11.15 runtime to create:

```text
D:\AI\TRIPPIN_AI_RELAY\tools\piper.venv
```

Installed locally:

- `piper-tts` 1.4.2
- Piper command: `tools\piper.venv\Scripts\piper.exe`
- Dependencies contained within the Relay-local venv

The approved install command remains:

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\TRIPPIN_AI_RELAY\scripts\install_piper_gated.ps1 -AllowInstall
```

The script remains dry-run by default. It refuses non-Python-3.11 environments and does not use global site packages.

No audio was generated or played. The approved v2.3 voice-model selection and download gate is described below.

## v2.2.1 verified venv path

The Piper installation path was verified as:

```text
D:\AI\TRIPPIN_AI_RELAY\tools\piper.venv
```

Verified state:

- Canonical venv exists and contains Python 3.11.15.
- `piper-tts` 1.4.2 is installed in the canonical venv.
- Legacy nested path `tools\piper\.venv` is absent.
- All Piper scripts and current documentation reference `tools\piper.venv`.
- Both canonical and legacy venv patterns remain ignored by Git.
- No migration or reinstall was required.
- The approved local test voice is defined as `en_US_lessac_medium`.
- Voice-model files belong under `tools\piper\voices` and stay ignored by Git.
- No audio was generated.

## v2.3 voice model selection and gated download

The approved local voice candidate is:

```text
en_US_lessac_medium
```

The local selection gate uses:

- `config\piper_voice_models.json`
- `scripts\download_piper_voice_model_gated.ps1`

The approved model pair is:

- `D:\AI\TRIPPIN_AI_RELAY\tools\piper\voices\en_US-lessac-medium.onnx`
- `D:\AI\TRIPPIN_AI_RELAY\tools\piper\voices\en_US-lessac-medium.onnx.json`

Safety boundary:

- Local testing only
- No audio generation yet
- No autoplay
- No Popout voice integration yet
- No microphone/audio capture
- No voice cloning
- No real-person or copyrighted-character impersonation
- Model card and license review are required before any distribution discussion

## Related files

- [Relay TTS Plan](RELAY_TTS_PLAN.md)
- [Relay Personality Guide](RELAY_PERSONALITY_GUIDE.md)
- [Relay Script Pack](RELAY_SCRIPT_PACK.md)
- `config/relay_voice_profiles.json`
- `scripts/check_relay_tts_feasibility.ps1`
- `scripts/check_piper_setup.ps1`
- `config/piper_voice_models.json`
- [Relay Piper Voice Model Selection](RELAY_PIPER_VOICE_MODEL_SELECTION.md)
- `scripts/download_piper_voice_model_gated.ps1`
- `scripts/prepare_piper_sandbox.ps1`
- `scripts/install_piper_gated.ps1`
- `scripts/run_piper_test_line_gated.ps1`
- `scripts/check_piper_python_runtime.ps1`
