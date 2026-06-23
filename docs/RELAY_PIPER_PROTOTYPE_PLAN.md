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

The first approved model must be original-sounding, license-reviewed, and placed manually under `tools\piper\models`. Actual Popout integration and automatic speech remain unimplemented.

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

The current recommendation is the available uv-managed Python 3.11 runtime. The planned future venv path is `D:\AI\TRIPPIN_AI_RELAY\tools\piper.venv`. The checker does not create it, install Python, install Piper, download models, or generate audio. The `-AllowInstall` gate remains manual-only until that runtime is explicitly approved.

## Related files

- [Relay TTS Plan](RELAY_TTS_PLAN.md)
- [Relay Personality Guide](RELAY_PERSONALITY_GUIDE.md)
- [Relay Script Pack](RELAY_SCRIPT_PACK.md)
- `config/relay_voice_profiles.json`
- `scripts/check_relay_tts_feasibility.ps1`
- `scripts/check_piper_setup.ps1`
- `scripts/prepare_piper_sandbox.ps1`
- `scripts/install_piper_gated.ps1`
- `scripts/run_piper_test_line_gated.ps1`
- `scripts/check_piper_python_runtime.ps1`
