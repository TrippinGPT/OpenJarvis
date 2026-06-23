[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent $PSScriptRoot
$prereqScript = Join-Path $repoRoot "scripts\check_kokoro_prereqs.ps1"

Write-Host ""
Write-Host "Relay Kokoro Feasibility Check" -ForegroundColor Magenta
Write-Host "Feasibility lane exists. Install readiness remains blocked until prerequisites are resolved." -ForegroundColor DarkGray

if (Test-Path -LiteralPath $prereqScript -PathType Leaf) {
    Write-Host ""
    Write-Host "Prerequisite prep lane" -ForegroundColor Cyan
    Write-Host $prereqScript
    Write-Host "Run this before any future Kokoro install attempt."
}
else {
    Write-Host ""
    Write-Host "Prerequisite prep lane" -ForegroundColor Cyan
    Write-Host "Missing prereq checker: $prereqScript" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Kokoro status" -ForegroundColor Cyan
Write-Host "- Planning-only"
Write-Host "- No install yet"
Write-Host "- No model download yet"
Write-Host "- No audio generation yet"
Write-Host "- No app/runtime TTS"
Write-Host "- No microphone/audio capture"
Write-Host "- No OpenClaw changes"
