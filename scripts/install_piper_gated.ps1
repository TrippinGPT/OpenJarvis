[CmdletBinding()]
param(
    [switch]$AllowInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedRepoRoot = [System.IO.Path]::GetFullPath("D:\AI\TRIPPIN_AI_RELAY")
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$piperRoot = Join-Path $repoRoot "tools\piper"
$localPython = Join-Path $piperRoot ".venv\Scripts\python.exe"

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to inspect or install Piper outside the expected Relay repo: $expectedRepoRoot"
}

function Get-VersionText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return "Not found"
    }

    try {
        $output = & $command.Source --version 2>&1
        $text = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join " "
        if ([string]::IsNullOrWhiteSpace($text)) {
            return "Available (version not reported)"
        }

        return $text
    }
    catch {
        return "Available (version check failed: $($_.Exception.Message))"
    }
}

function Test-PiperModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath
    )

    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
        return $false
    }

    & $PythonPath -c "import importlib.util; raise SystemExit(0 if importlib.util.find_spec('piper') else 1)" 2>$null
    return ($LASTEXITCODE -eq 0)
}

$piperCommand = Get-Command "piper" -ErrorAction SilentlyContinue | Select-Object -First 1
$localModuleAvailable = Test-PiperModule -PythonPath $localPython

Write-Host ""
Write-Host "Relay Piper Gated Install" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowInstall) { 'APPROVAL GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current status" -ForegroundColor Cyan
Write-Host "- Candidate lane: piper-tts from OHF-Voice/piper1-gpl"
Write-Host "- System Python: $(Get-VersionText -CommandName 'python')"
Write-Host "- uv: $(Get-VersionText -CommandName 'uv')"
Write-Host "- Local virtual environment: $(if (Test-Path -LiteralPath $localPython -PathType Leaf) { $localPython } else { 'Not found' })"
Write-Host "- Local Piper module: $(if ($localModuleAvailable) { 'Available' } else { 'Not found' })"
Write-Host "- Piper command: $(if ($null -ne $piperCommand) { $piperCommand.Source } else { 'Not installed' })"
Write-Host ""

if (-not $AllowInstall) {
    Write-Host "Dry-run checks only:" -ForegroundColor Yellow
    Write-Host "- Verify the Relay-local Piper sandbox."
    Write-Host "- Verify uv and a compatible Python interpreter."
    Write-Host "- Review the OHF Piper source, package version, GPL license, and Windows compatibility."
    Write-Host "- Plan an isolated virtual environment under tools\piper\.venv."
    Write-Host ""
    Write-Host "Actual installation requires -AllowInstall." -ForegroundColor Yellow
}
else {
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "PIPER INSTALL APPROVAL GATE REQUESTED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "v2.1 keeps this gate manual-only. No install command will run." -ForegroundColor Yellow
    Write-Host "Reason: the current machine reports Python 3.14, while the reviewed piper-tts package metadata explicitly lists support through Python 3.13." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual next steps for a future approved task:"
    Write-Host "1. Select and verify a compatible local Python interpreter."
    Write-Host "2. Pin and review the intended piper-tts version and GPL-3.0-or-later license."
    Write-Host "3. Define the exact uv commands for tools\piper\.venv."
    Write-Host "4. Print those commands before execution and verify the local piper module afterward."
    Write-Host "5. Keep all installation files inside the Relay repository."
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No package installed"
Write-Host "- No model downloaded"
Write-Host "- No environment modified"
Write-Host "- No audio generated or played"
Write-Host "- No microphone/audio capture used"
Write-Host "- OpenClaw was not touched"
