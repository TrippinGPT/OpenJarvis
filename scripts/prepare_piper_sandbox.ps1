[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedRepoRoot = [System.IO.Path]::GetFullPath("D:\AI\TRIPPIN_AI_RELAY")
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$repoRootPrefix = $repoRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to prepare Piper sandbox outside the expected Relay repo: $expectedRepoRoot"
}

$sandboxDefinitions = @(
    [pscustomobject]@{
        Name = "Piper tools sandbox"
        Folder = Join-Path $repoRoot "tools\piper"
        Readme = @'
# Relay Piper Sandbox

## Purpose

This directory is the local sandbox location reserved for a future approved Piper prototype.

## Current status

- Empty planning folder
- Piper is not installed
- No Piper binary or voice model has been downloaded
- No TTS runtime or audio generation is configured

A future explicitly approved setup may place reviewed Piper binaries and local configuration notes here.

## Boundaries

- Do not commit large binaries or downloaded voice-model files without explicit review.
- Review source, version, license, and checksums before adding future tools or models.
- Do not clone or imitate a real person.
- Do not impersonate a copyrighted character.
- The Relay voice must remain original.
- Do not add microphone or audio-capture behavior.
- Do not modify OpenClaw from this sandbox.
'@
    }
    [pscustomobject]@{
        Name = "TTS test outputs"
        Folder = Join-Path $repoRoot "outputs\tts_tests"
        Readme = @'
# Relay TTS Test Outputs

## Purpose

This directory is reserved for future local Relay TTS test output.

## Current status

- No audio has been generated.
- No voice samples are stored here.
- No playback or application integration is configured.

Future explicitly approved tests may save temporary Relay voice samples here.

## Boundaries

- Do not commit generated audio unless explicitly approved.
- Do not store private, sensitive, or third-party audio.
- Do not store cloned voices or impersonations.
- Use only an original Relay voice.
- The first approved test line should come from `config/relay_voice_profiles.json` or `docs/RELAY_SCRIPT_PACK.md`.
- Do not auto-play generated output unless explicitly approved.
'@
    }
)

function Assert-RelayPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($repoRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside the Relay repo: $fullPath"
    }

    return $fullPath
}

function Get-SandboxStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder
    )

    $readmePath = Join-Path $Folder "README.md"
    $folderExists = Test-Path -LiteralPath $Folder -PathType Container
    $readmeExists = Test-Path -LiteralPath $readmePath -PathType Leaf

    return "folder=$folderExists, README=$readmeExists"
}

Write-Host ""
Write-Host "Relay Piper Sandbox Prep" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status before" -ForegroundColor Cyan

foreach ($sandbox in $sandboxDefinitions) {
    $folder = Assert-RelayPath -Path $sandbox.Folder
    Write-Host ("- {0}: {1}" -f $sandbox.Name, (Get-SandboxStatus -Folder $folder))
}

foreach ($sandbox in $sandboxDefinitions) {
    $folder = Assert-RelayPath -Path $sandbox.Folder
    $readmePath = Assert-RelayPath -Path (Join-Path $folder "README.md")

    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }

    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
        Set-Content -LiteralPath $readmePath -Value $sandbox.Readme -Encoding UTF8
    }
}

Write-Host ""
Write-Host "Status after" -ForegroundColor Cyan
foreach ($sandbox in $sandboxDefinitions) {
    $folder = Assert-RelayPath -Path $sandbox.Folder
    Write-Host ("- {0}: {1}" -f $sandbox.Name, (Get-SandboxStatus -Folder $folder))
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No install occurred"
Write-Host "- No download occurred"
Write-Host "- No audio was generated or played"
Write-Host "- No microphone/audio capture occurred"
Write-Host "- OpenClaw was not touched"
Write-Host "- Only the two approved Relay sandbox folders and missing README files were eligible for creation"
