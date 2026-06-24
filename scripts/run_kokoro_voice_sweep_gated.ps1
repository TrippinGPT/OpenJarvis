[CmdletBinding()]
param(
    [switch]$AllowModelDownload,
    [switch]$AllowGenerate,
    [string]$PythonExe,
    [string[]]$Voices,
    [string[]]$Lines
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedRepoRoot = [System.IO.Path]::GetFullPath("D:\AI\TRIPPIN_AI_RELAY")
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$repoRootPrefix = $repoRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to run Kokoro outside the expected Relay repo: $expectedRepoRoot"
}

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = Join-Path $repoRoot "tools\kokoro.venv\Scripts\python.exe"
}

function Assert-RelayPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($repoRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use path outside the Relay repo: $fullPath"
    }

    return $fullPath
}

function Get-Count {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        return 0
    }

    return @(
        Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue
    ).Count
}

function Get-LatestFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        return $null
    }

    return Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Test-GitIgnoredPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    & git -C $repoRoot check-ignore -q -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Get-KokoroProfileConfig {
    $profilePath = Join-Path $repoRoot "config\relay_voice_profiles.json"
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        throw "Missing voice profile config: $profilePath"
    }

    try {
        return [pscustomobject]@{
            Path = $profilePath
            Config = (Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json)
        }
    }
    catch {
        throw "Voice profile config is invalid: $($_.Exception.Message)"
    }
}

function Get-DefaultSweepVoices {
    return @("af_heart", "af_bella", "af_nova", "am_michael")
}

function Get-AllowedSweepVoices {
    return @(
        "af_heart",
        "af_alloy",
        "af_aoede",
        "af_bella",
        "af_jessica",
        "af_kore",
        "af_nicole",
        "af_nova",
        "af_river",
        "af_sarah",
        "af_sky",
        "am_adam",
        "am_echo",
        "am_eric",
        "am_fenrir",
        "am_liam",
        "am_michael",
        "am_onyx",
        "am_puck",
        "am_santa"
    )
}

function Get-SweepVoices {
    param([string[]]$RequestedVoices)

    $voices = if ($RequestedVoices -and $RequestedVoices.Count -gt 0) {
        @(
            $RequestedVoices |
                ForEach-Object { "$_".Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
    }
    else {
        @(Get-DefaultSweepVoices)
    }

    $allowed = @(Get-AllowedSweepVoices)
    foreach ($voice in $voices) {
        if ($allowed -notcontains $voice) {
            throw "Unsupported Kokoro voice id '$voice'. Use official Kokoro English voices only."
        }
    }

    return $voices
}

function Get-SweepLines {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ProfileConfig,

        [string[]]$RequestedLines
    )

    if ($RequestedLines -and $RequestedLines.Count -gt 0) {
        return @(
            $RequestedLines |
                ForEach-Object { "$_".Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
    }

    $defaultProfileId = "smartmouth_relay"
    if ($ProfileConfig.Config.PSObject.Properties.Name -contains "default_voice") {
        $defaultProfileId = [string]$ProfileConfig.Config.default_voice
    }

    $profile = $ProfileConfig.Config.voices |
        Where-Object { $_.id -eq $defaultProfileId } |
        Select-Object -First 1
    if ($null -eq $profile) {
        $profile = $ProfileConfig.Config.voices |
            Where-Object { $_.id -eq "smartmouth_relay" } |
            Select-Object -First 1
    }

    $profileLines = @()
    if ($null -ne $profile -and $profile.PSObject.Properties.Name -contains "do_say") {
        $profileLines = @(
            $profile.do_say |
                ForEach-Object { "$_".Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -First 3
        )
    }

    if ($profileLines.Count -gt 0) {
        return $profileLines
    }

    return @(
        "Relay online. Try not to break anything expensive.",
        "Routing that now. Shocking development: we are using a plan.",
        "I can make this faster, cleaner, and less cursed."
    )
}

function Invoke-PythonProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
        return [pscustomobject]@{
            Available = $false
            Success = $false
            Output = @("Not found")
        }
    }

    try {
        $output = @(& $PythonPath @Arguments 2>&1)
        return [pscustomobject]@{
            Available = $true
            Success = ($LASTEXITCODE -eq 0)
            Output = $output
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $true
            Success = $false
            Output = @($_.Exception.Message)
        }
    }
}

function Get-KokoroPythonStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath
    )

    $versionProbe = Invoke-PythonProbe -PythonPath $PythonPath -Arguments @("--version")
    $versionText = ($versionProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($versionText)) {
        $versionText = "Not found"
    }
    $versionOk = $versionText -match '^Python 3\.11(\.|$)'

    $pipShowProbe = Invoke-PythonProbe -PythonPath $PythonPath -Arguments @("-m", "pip", "show", "kokoro")
    $pipShowText = ($pipShowProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
    $kokoroInstalled = $false
    $kokoroVersion = "Not found"
    if ($pipShowProbe.Available -and $pipShowProbe.Success -and $pipShowText -match '(?m)^Name:\s+kokoro\s*$') {
        $kokoroInstalled = $true
        if ($pipShowText -match '(?m)^Version:\s+(.+)$') {
            $kokoroVersion = $matches[1]
        }
    }

    $importProbe = Invoke-PythonProbe -PythonPath $PythonPath -Arguments @("-c", "import kokoro; print(kokoro.__file__)")
    $kokoroImportPath = ($importProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    $kokoroImportOk = $importProbe.Available -and $importProbe.Success -and -not [string]::IsNullOrWhiteSpace($kokoroImportPath)

    return [pscustomobject]@{
        Exists = (Test-Path -LiteralPath $PythonPath -PathType Leaf)
        VersionText = $versionText
        VersionOk = $versionOk
        KokoroInstalled = $kokoroInstalled
        KokoroVersion = $kokoroVersion
        KokoroImportOk = $kokoroImportOk
        KokoroImportPath = $(if ($kokoroImportOk) { $kokoroImportPath } else { "Not found" })
        Healthy = $versionOk -and $kokoroInstalled -and $kokoroImportOk
    }
}

$pythonExePath = Assert-RelayPath -Path $PythonExe
$profileConfig = Get-KokoroProfileConfig
$selectedVoices = @(Get-SweepVoices -RequestedVoices $Voices)
$selectedLines = @(Get-SweepLines -ProfileConfig $profileConfig -RequestedLines $Lines)
$selectedLineSource = if ($null -ne $Lines -and $Lines.Count -gt 0) { "command line" } else { "config\relay_voice_profiles.json:smartmouth_relay.do_say[0..2]" }
$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputRoot = Join-Path $repoRoot "outputs\tts_tests"
$kokoroCachePath = Join-Path $repoRoot "tools\kokoro\models"
$selectedOutputs = @()
foreach ($voice in $selectedVoices) {
    foreach ($index in 0..($selectedLines.Count - 1)) {
        $lineNumber = $index + 1
        $selectedOutputs += [pscustomobject]@{
            Voice = $voice
            LineNumber = $lineNumber
            PlannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot ("relay_kokoro_sweep_{0}_line{1:00}_{2}.wav" -f $voice, $lineNumber, $runStamp))
        }
    }
}

$pythonStatus = Get-KokoroPythonStatus -PythonPath $pythonExePath
$cacheExists = Test-Path -LiteralPath $kokoroCachePath -PathType Container
$cacheFileCount = Get-Count -Folder $kokoroCachePath -Filter "*"
$existingSweepCount = Get-Count -Folder $outputRoot -Filter "relay_kokoro_sweep_*.wav"
$latestSweepWav = Get-LatestFile -Folder $outputRoot -Filter "relay_kokoro_sweep_*.wav"
$latestSweepWavPath = if ($null -ne $latestSweepWav) { $latestSweepWav.FullName } else { "None" }
$ignoreChecks = [ordered]@{
    "tools/kokoro.venv/" = (Test-GitIgnoredPattern -Path "tools/kokoro.venv/placeholder.txt")
    "tools/kokoro/models/" = (Test-GitIgnoredPattern -Path "tools/kokoro/models/placeholder.bin")
    "outputs/tts_tests/*.wav" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.wav")
    "outputs/tts_tests/*.mp3" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.mp3")
}

Write-Host ""
Write-Host "Relay Kokoro Voice Sweep" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f $(if ($AllowGenerate) { "generation requested" } elseif ($AllowModelDownload) { "prefetch requested" } else { "dry run" }))
Write-Host ""

Write-Host "Selected Python" -ForegroundColor Cyan
Write-Host "- path: $pythonExePath"
Write-Host "- exists: $($pythonStatus.Exists)"
Write-Host "- version: $($pythonStatus.VersionText)"
Write-Host "- version is 3.11.x: $($pythonStatus.VersionOk)"
Write-Host "- kokoro package installed: $($pythonStatus.KokoroInstalled)"
Write-Host "- kokoro package version: $($pythonStatus.KokoroVersion)"
Write-Host "- kokoro import: $(if ($pythonStatus.KokoroImportOk) { $pythonStatus.KokoroImportPath } else { 'Not found' })"
Write-Host "- venv python healthy: $($pythonStatus.Healthy)"
Write-Host ""

Write-Host "Sweep set" -ForegroundColor Cyan
Write-Host "- voice count: $($selectedVoices.Count)"
Write-Host "- line count: $($selectedLines.Count)"
Write-Host "- line source: $selectedLineSource"
Write-Host ""
Write-Host "Voices" -ForegroundColor Cyan
foreach ($voice in $selectedVoices) {
    Write-Host "- $voice"
}
Write-Host ""
Write-Host "Lines" -ForegroundColor Cyan
for ($i = 0; $i -lt $selectedLines.Count; $i++) {
    Write-Host ("- line {0}: {1}" -f ($i + 1), $selectedLines[$i])
}
Write-Host ""
Write-Host "Local cache" -ForegroundColor Cyan
Write-Host "- cache path: $kokoroCachePath"
Write-Host "- cache present: $cacheExists"
Write-Host "- cache file count: $cacheFileCount"
Write-Host "- existing sweep WAV count: $existingSweepCount"
Write-Host "- latest sweep WAV: $latestSweepWavPath"
Write-Host ""
Write-Host "Planned outputs" -ForegroundColor Cyan
foreach ($plan in $selectedOutputs) {
    Write-Host ("- {0} (voice {1}, line {2})" -f $plan.PlannedOutput, $plan.Voice, $plan.LineNumber)
}
Write-Host ""

if (-not $pythonStatus.Exists) {
    throw "Selected Kokoro Python path does not exist: $pythonExePath"
}
if (-not $pythonStatus.VersionOk) {
    throw "Selected Kokoro Python must be Python 3.11.x: $($pythonStatus.VersionText)"
}
if (-not $pythonStatus.KokoroInstalled) {
    throw "Selected Kokoro Python does not report an installed kokoro package: $pythonExePath"
}
if (-not $pythonStatus.KokoroImportOk) {
    throw "Selected Kokoro Python cannot import kokoro from the local venv: $pythonExePath"
}

if (-not $AllowModelDownload -and -not $AllowGenerate) {
    Write-Host "Dry run complete. No audio was generated." -ForegroundColor Yellow
    Write-Host "Run with -AllowModelDownload to prefetch the Kokoro model and voice cache without writing WAVs."
    Write-Host "Run with -AllowModelDownload -AllowGenerate to produce the sweep WAV set."
    Write-Host "No playback occurred."
    Write-Host "No microphone access occurred."
    Write-Host "No app runtime TTS was added."
    Write-Host "OpenClaw was not touched."
    Write-Host ""
    Write-Host "Git ignore readiness" -ForegroundColor Cyan
    foreach ($item in $ignoreChecks.GetEnumerator()) {
        Write-Host ("- {0}: {1}" -f $item.Key, $(if ($item.Value) { "Covered" } else { "Not covered" }))
    }
    exit 0
}

if ($AllowGenerate -and -not $AllowModelDownload) {
    throw "Sweep generation is gated. Re-run with -AllowModelDownload -AllowGenerate."
}

if ($AllowGenerate -and -not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
}

if ($AllowModelDownload -or $AllowGenerate) {
    New-Item -ItemType Directory -Path $kokoroCachePath -Force | Out-Null
    $env:HF_HUB_CACHE = $kokoroCachePath
    $env:HUGGINGFACE_HUB_CACHE = $kokoroCachePath
}

$pythonScript = Join-Path $env:TEMP ("relay_kokoro_voice_sweep_{0}.py" -f ([guid]::NewGuid().ToString("N")))
$voicesJsonPath = Join-Path $env:TEMP ("relay_kokoro_voice_sweep_voices_{0}.json" -f ([guid]::NewGuid().ToString("N")))
$linesJsonPath = Join-Path $env:TEMP ("relay_kokoro_voice_sweep_lines_{0}.json" -f ([guid]::NewGuid().ToString("N")))
(ConvertTo-Json -Compress -InputObject @($selectedVoices)) | Set-Content -LiteralPath $voicesJsonPath -Encoding UTF8
(ConvertTo-Json -Compress -InputObject @($selectedLines)) | Set-Content -LiteralPath $linesJsonPath -Encoding UTF8

@"
import json
import os
import sys
import wave
from pathlib import Path

import numpy as np

mode = sys.argv[1]
output_root = Path(sys.argv[2])
cache_path = sys.argv[3]
run_stamp = sys.argv[4]
voices = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8-sig"))
lines = json.loads(Path(sys.argv[6]).read_text(encoding="utf-8-sig"))

os.environ["HF_HUB_CACHE"] = cache_path
os.environ["HUGGINGFACE_HUB_CACHE"] = cache_path

from kokoro import KPipeline

pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M", device="cpu")

for voice in voices:
    pipeline.load_voice(voice)

if mode == "prefetch":
    print(f"Prefetched Kokoro model and voices: {', '.join(voices)}")
    raise SystemExit(0)

output_root.mkdir(parents=True, exist_ok=True)

written = []
for voice in voices:
    for index, text in enumerate(lines, start=1):
        output_path = output_root / f"relay_kokoro_sweep_{voice}_line{index:02d}_{run_stamp}.wav"
        if output_path.exists():
            raise RuntimeError(f"Output already exists: {output_path}")

        with wave.open(str(output_path.resolve()), "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(24000)

            for result in pipeline(text, voice=voice, speed=1.0, split_pattern=r"\n+"):
                if result.audio is None:
                    continue
                audio_bytes = (result.audio.numpy() * 32767).astype(np.int16).tobytes()
                wav_file.writeframes(audio_bytes)

        size = output_path.stat().st_size
        written.append((str(output_path), size))
        print(f"Wrote WAV: {output_path} ({size} bytes)")

print(f"Generated {len(written)} sweep WAV file(s).")
"@ | Set-Content -LiteralPath $pythonScript -Encoding UTF8

try {
    if ($AllowModelDownload -and -not $AllowGenerate) {
        Write-Host "Prefetch requested. Kokoro model and official voice cache may download, but no WAV will be written." -ForegroundColor Cyan
        & $pythonExePath $pythonScript "prefetch" $outputRoot $kokoroCachePath $runStamp $voicesJsonPath $linesJsonPath
        if ($LASTEXITCODE -ne 0) {
            throw "Kokoro prefetch exited with code $LASTEXITCODE."
        }

        Write-Host ""
        Write-Host "Prefetch result" -ForegroundColor Green
        Write-Host "- Model cache path: $kokoroCachePath"
        Write-Host "- Voices prefetched: $($selectedVoices -join ', ')"
        Write-Host "- No audio generated."
        Write-Host "- No playback occurred."
        Write-Host "- No microphone access occurred."
        Write-Host "- No app runtime TTS was added."
        Write-Host "- OpenClaw was not touched."
    }
    elseif ($AllowGenerate) {
        Write-Host "Generation requested. Kokoro may use the local cache or download the approved assets into the Relay cache path." -ForegroundColor Cyan
        foreach ($plan in $selectedOutputs) {
            if (Test-Path -LiteralPath $plan.PlannedOutput -PathType Leaf) {
                throw "Planned output already exists: $($plan.PlannedOutput)"
            }
        }

        & $pythonExePath $pythonScript "generate" $outputRoot $kokoroCachePath $runStamp $voicesJsonPath $linesJsonPath
        if ($LASTEXITCODE -ne 0) {
            throw "Kokoro sweep generation exited with code $LASTEXITCODE."
        }

        $generatedCount = Get-Count -Folder $outputRoot -Filter "relay_kokoro_sweep_*.wav"
        Write-Host ""
        Write-Host "Generation result" -ForegroundColor Green
        Write-Host "- Sweep WAV count: $generatedCount"
        Write-Host "- Cache path: $kokoroCachePath"
        Write-Host "- No playback occurred."
        Write-Host "- No microphone access occurred."
        Write-Host "- No app runtime TTS was added."
        Write-Host "- OpenClaw was not touched."
        Write-Host ""
        Write-Host "Generated WAVs" -ForegroundColor Cyan
        Get-ChildItem -LiteralPath $outputRoot -File -Filter "relay_kokoro_sweep_*.wav" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime, FullName |
            ForEach-Object {
                Write-Host ("- {0} ({1} bytes)" -f $_.FullName, $_.Length)
            }
    }
}
finally {
    if (Test-Path -LiteralPath $pythonScript -PathType Leaf) {
        Remove-Item -LiteralPath $pythonScript -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $voicesJsonPath -PathType Leaf) {
        Remove-Item -LiteralPath $voicesJsonPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $linesJsonPath -PathType Leaf) {
        Remove-Item -LiteralPath $linesJsonPath -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Git ignore readiness" -ForegroundColor Cyan
foreach ($item in $ignoreChecks.GetEnumerator()) {
    Write-Host ("- {0}: {1}" -f $item.Key, $(if ($item.Value) { "Covered" } else { "Not covered" }))
}
Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No browser shell execution"
Write-Host "- No automatic speech"
Write-Host "- No voice cloning or impersonation"
Write-Host "- No OpenClaw modifications"
