[CmdletBinding()]
param(
    [switch]$AllowModelDownload,
    [switch]$AllowGenerate,
    [string]$VoiceId = "af_heart",
    [string]$Line
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

function Get-KokoroLineSelection {
    param(
        [AllowEmptyString()]
        [string]$RequestedLine
    )

    $fallbackLine = "Relay online. Try not to break anything expensive."
    $profilePath = Join-Path $repoRoot "config\relay_voice_profiles.json"

    if (-not [string]::IsNullOrWhiteSpace($RequestedLine)) {
        return [pscustomobject]@{
            Line = $RequestedLine.Trim()
            Source = "command line"
        }
    }

    if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
        try {
            $profileConfig = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
            $defaultProfileId = $null
            if ($profileConfig.PSObject.Properties.Name -contains "default_voice") {
                $defaultProfileId = [string]$profileConfig.default_voice
            }
            elseif ($profileConfig.PSObject.Properties.Name -contains "default_voice_id") {
                $defaultProfileId = [string]$profileConfig.default_voice_id
            }

            if ([string]::IsNullOrWhiteSpace($defaultProfileId)) {
                $defaultProfileId = "smartmouth_relay"
            }

            $profile = $profileConfig.voices |
                Where-Object { $_.id -eq $defaultProfileId } |
                Select-Object -First 1
            if ($null -eq $profile) {
                $profile = $profileConfig.voices |
                    Where-Object { $_.id -eq "smartmouth_relay" } |
                    Select-Object -First 1
            }

            if ($null -ne $profile -and @($profile.do_say).Count -gt 0) {
                return [pscustomobject]@{
                    Line = [string]$profile.do_say[0]
                    Source = "config\relay_voice_profiles.json:$($profile.id)"
                }
            }
        }
        catch {
        }
    }

    return [pscustomobject]@{
        Line = $fallbackLine
        Source = "fallback"
    }
}

function Get-KokoroPackageStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath
    )

    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
        return [pscustomobject]@{
            Installed = $false
            Version = "Not found"
        }
    }

    try {
        $output = @(& $PythonPath -m pip show kokoro 2>&1)
        $text = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
        if ($LASTEXITCODE -eq 0 -and $text -match '(?m)^Name:\s+kokoro\s*$') {
            $version = "Unknown"
            if ($text -match '(?m)^Version:\s+(.+)$') {
                $version = $matches[1]
            }

            return [pscustomobject]@{
                Installed = $true
                Version = $version
            }
        }
    }
    catch {
    }

    return [pscustomobject]@{
        Installed = $false
        Version = "Not found"
    }
}

$kokoroVenvPython = Join-Path $repoRoot "tools\kokoro.venv\Scripts\python.exe"
$kokoroCachePath = Join-Path $repoRoot "tools\kokoro\models"
$outputRoot = Join-Path $repoRoot "outputs\tts_tests"
$selectedLine = Get-KokoroLineSelection -RequestedLine $Line
$selectedVoice = if ([string]::IsNullOrWhiteSpace($VoiceId)) { "af_heart" } else { $VoiceId.Trim() }
$selectedLanguage = $selectedVoice.Substring(0, 1).ToLowerInvariant()
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$plannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot ("relay_kokoro_first_{0}.wav" -f $timestamp))
$kokoroPackageStatus = Get-KokoroPackageStatus -PythonPath $kokoroVenvPython
$venvPythonExists = Test-Path -LiteralPath $kokoroVenvPython -PathType Leaf
$cacheExists = Test-Path -LiteralPath $kokoroCachePath -PathType Container
$cacheFileCount = Get-Count -Folder $kokoroCachePath -Filter "*"
$firstWavCount = Get-Count -Folder $outputRoot -Filter "relay_kokoro_first_*.wav"

Write-Host ""
Write-Host "Relay Kokoro First WAV Test" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f $(if ($AllowGenerate) { "generation requested" } elseif ($AllowModelDownload) { "prefetch requested" } else { "dry run" }))
Write-Host ""

Write-Host "Selected voice" -ForegroundColor Cyan
Write-Host "- voice id: $selectedVoice"
Write-Host "- language: $selectedLanguage"
Write-Host "- venv python: $kokoroVenvPython"
Write-Host "- venv python present: $venvPythonExists"
Write-Host "- kokoro package: $(if ($kokoroPackageStatus.Installed) { "Installed ($($kokoroPackageStatus.Version))" } else { "Missing" })"
Write-Host ""

Write-Host "Selected line" -ForegroundColor Cyan
Write-Host "- source: $($selectedLine.Source)"
Write-Host "- text: $($selectedLine.Line)"
Write-Host "- planned output: $plannedOutput"
Write-Host ""

Write-Host "Local cache" -ForegroundColor Cyan
Write-Host "- cache path: $kokoroCachePath"
Write-Host "- cache present: $cacheExists"
Write-Host "- cache file count: $cacheFileCount"
Write-Host "- first WAV count: $firstWavCount"
Write-Host ""

if (-not $AllowModelDownload -and -not $AllowGenerate) {
    Write-Host "Dry run complete. No audio was generated." -ForegroundColor Yellow
    Write-Host "Run with -AllowModelDownload to prefetch the Kokoro cache without writing a WAV."
    Write-Host "Run with -AllowModelDownload -AllowGenerate to produce the first local Kokoro WAV."
    Write-Host "No playback occurred."
    Write-Host "No microphone access occurred."
    Write-Host "No app runtime TTS was added."
    Write-Host "OpenClaw was not touched."
    return
}

if (-not $venvPythonExists) {
    throw "Kokoro venv Python is missing: $kokoroVenvPython"
}

if (-not $kokoroPackageStatus.Installed) {
    throw "Kokoro is not installed in the local venv: $kokoroVenvPython"
}

if (-not (Test-Path -LiteralPath $outputRoot -PathType Container) -and $AllowGenerate) {
    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
}

if ($AllowModelDownload -or $AllowGenerate) {
    New-Item -ItemType Directory -Path $kokoroCachePath -Force | Out-Null
    $env:HF_HUB_CACHE = $kokoroCachePath
    $env:HUGGINGFACE_HUB_CACHE = $kokoroCachePath
}

if ($AllowGenerate -and -not $AllowModelDownload -and -not $cacheExists) {
    throw "Kokoro cache is missing. Re-run with -AllowModelDownload -AllowGenerate to authorize the first download and WAV generation."
}

$tempPythonScript = Join-Path $env:TEMP ("relay_kokoro_first_{0}.py" -f ([guid]::NewGuid().ToString("N")))

@"
import os
import sys
import wave
from pathlib import Path

import numpy as np
from kokoro import KPipeline

mode = sys.argv[1]
voice = sys.argv[2]
output_path = Path(sys.argv[3])
text = sys.argv[4]
cache_path = sys.argv[5]

if cache_path:
    os.environ["HF_HUB_CACHE"] = cache_path
    os.environ["HUGGINGFACE_HUB_CACHE"] = cache_path

pipeline = KPipeline(lang_code=voice[0].lower(), repo_id="hexgrad/Kokoro-82M", device="cpu")
pipeline.load_voice(voice)

if mode == "prefetch":
    print(f"Prefetched Kokoro model and voice cache for {voice}.")
    raise SystemExit(0)

with wave.open(str(output_path.resolve()), "wb") as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(24000)

    for result in pipeline(text, voice=voice, speed=1.0, split_pattern=r"\n+"):
        if result.audio is None:
            continue
        audio_bytes = (result.audio.numpy() * 32767).astype(np.int16).tobytes()
        wav_file.writeframes(audio_bytes)

print(f"Wrote WAV: {output_path}")
"@ | Set-Content -LiteralPath $tempPythonScript -Encoding UTF8

try {
    if ($AllowModelDownload -and -not $AllowGenerate) {
        Write-Host "Prefetch requested. Kokoro model and voice cache may download, but no WAV will be written." -ForegroundColor Cyan
        & $kokoroVenvPython $tempPythonScript "prefetch" $selectedVoice $plannedOutput $selectedLine.Line $kokoroCachePath
        if ($LASTEXITCODE -ne 0) {
            throw "Kokoro prefetch exited with code $LASTEXITCODE."
        }

        Write-Host ""
        Write-Host "Prefetch result" -ForegroundColor Green
        Write-Host "- Model cache path: $kokoroCachePath"
        Write-Host "- No audio generated."
        Write-Host "- No playback occurred."
        Write-Host "- No microphone access occurred."
        Write-Host "- No app runtime TTS was added."
        Write-Host "- OpenClaw was not touched."
    }
    else {
        if (-not $AllowGenerate) {
            return
        }

        Write-Host "Generation requested. Kokoro may use the local cache or download the approved assets into the Relay cache path." -ForegroundColor Cyan
        if (Test-Path -LiteralPath $plannedOutput -PathType Leaf) {
            throw "Planned output already exists: $plannedOutput"
        }

        & $kokoroVenvPython $tempPythonScript "generate" $selectedVoice $plannedOutput $selectedLine.Line $kokoroCachePath
        if ($LASTEXITCODE -ne 0) {
            throw "Kokoro WAV generation exited with code $LASTEXITCODE."
        }

        if (-not (Test-Path -LiteralPath $plannedOutput -PathType Leaf)) {
            throw "Expected Kokoro WAV was not created: $plannedOutput"
        }

        $generatedFile = Get-Item -LiteralPath $plannedOutput
        Write-Host ""
        Write-Host "Generation result" -ForegroundColor Green
        Write-Host "- Output WAV: $plannedOutput"
        Write-Host "- File size: $($generatedFile.Length) bytes"
        Write-Host "- Cache path: $kokoroCachePath"
        Write-Host "- No playback occurred."
        Write-Host "- No microphone access occurred."
        Write-Host "- No app runtime TTS was added."
        Write-Host "- OpenClaw was not touched."
    }
}
finally {
    if (Test-Path -LiteralPath $tempPythonScript -PathType Leaf) {
        Remove-Item -LiteralPath $tempPythonScript -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No browser shell execution"
Write-Host "- No automatic speech"
Write-Host "- No voice cloning or impersonation"
Write-Host "- No OpenClaw modifications"
