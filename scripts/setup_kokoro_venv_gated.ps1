[CmdletBinding()]
param(
    [switch]$AllowSetup,

    [string]$Python311Path,

    [switch]$SkipPackageInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedRepoRoot = [System.IO.Path]::GetFullPath('D:\AI\TRIPPIN_AI_RELAY')
$openClawRoot = [System.IO.Path]::GetFullPath('D:\AI\OPENCLAW')
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repoRootPrefix = $repoRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$currentLocation = [System.IO.Path]::GetFullPath((Get-Location).Path)
$kokoroToolsPath = Join-Path $repoRoot 'tools\kokoro'
$kokoroVenvPath = Join-Path $repoRoot 'tools\kokoro.venv'
$kokoroVenvPython = Join-Path $kokoroVenvPath 'Scripts\python.exe'
$prereqScript = Join-Path $repoRoot 'scripts\check_kokoro_prereqs.ps1'
$espeakFallbackPath = 'C:\Program Files\eSpeak NG\espeak-ng.exe'
$knownUvPython311 = Join-Path $env:APPDATA 'uv\python\cpython-3.11.15-windows-x86_64-none\python.exe'

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to set up Kokoro outside the expected Relay repo: $expectedRepoRoot"
}

if ($currentLocation.StartsWith($openClawRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to run Kokoro setup from inside OpenClaw: $openClawRoot"
}

function Write-SetupLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-36} {1}" -f "${Label}:", $Value)
}

function Invoke-OptionalExecutableCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Available = $false
            Success = $false
            Output = @("Not found")
            Path = $null
        }
    }

    try {
        $output = @(& $Path @Arguments 2>&1)
        return [pscustomobject]@{
            Available = $true
            Success = ($LASTEXITCODE -eq 0)
            Output = $output
            Path = $Path
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $true
            Success = $false
            Output = @($_.Exception.Message)
            Path = $Path
        }
    }
}

function Get-Python311Candidate {
    param(
        [string]$OverridePath
    )

    $candidates = New-Object System.Collections.ArrayList

    if (-not [string]::IsNullOrWhiteSpace($OverridePath)) {
        if (Test-Path -LiteralPath $OverridePath -PathType Leaf) {
            [void]$candidates.Add([pscustomobject]@{
                Source = '-Python311Path'
                Path = $OverridePath
            })
        }
    }
    else {
        $pyCommand = Get-Command py -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $pyCommand) {
            $inventory = @(& $pyCommand.Source -0p 2>&1)
            foreach ($line in $inventory) {
                $text = [string]$line
                if ($text -match 'Astral/CPython3\.11|cpython-3\.11') {
                    if ($text -match '([A-Za-z]:\\[^"''\r\n]+python\.exe)\s*$') {
                        [void]$candidates.Add([pscustomobject]@{
                            Source = 'py -0p'
                            Path = $matches[1]
                        })
                    }
                }
            }
        }

        if (Test-Path -LiteralPath $knownUvPython311 -PathType Leaf) {
            [void]$candidates.Add([pscustomobject]@{
                Source = 'known uv path'
                Path = $knownUvPython311
            })
        }
    }

    foreach ($candidate in $candidates) {
        $info = Invoke-OptionalExecutableCommand -Path $candidate.Path -Arguments @('--version')
        if ($info.Available -and $info.Success) {
            $version = ($info.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
            if ($version -match '^Python 3\.11(\.|$)') {
                return [pscustomobject]@{
                    Found = $true
                    Source = $candidate.Source
                    Path = $candidate.Path
                    Version = $version
                }
            }
        }
    }

    return [pscustomobject]@{
        Found = $false
        Source = 'none'
        Path = $null
        Version = 'Not found'
    }
}

function Get-EspeakNgCandidate {
    $command = Get-Command espeak-ng -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) {
        return [pscustomobject]@{
            Found = $true
            Source = 'PATH'
            Path = $command.Source
        }
    }

    if (Test-Path -LiteralPath $espeakFallbackPath -PathType Leaf) {
        return [pscustomobject]@{
            Found = $true
            Source = 'Program Files'
            Path = $espeakFallbackPath
        }
    }

    return [pscustomobject]@{
        Found = $false
        Source = 'missing'
        Path = $null
    }
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Command
        $commandExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($commandExitCode -ne 0) {
        throw "$FailureMessage Exit code: $commandExitCode"
    }
}

$selectedPython = Get-Python311Candidate -OverridePath $Python311Path
$espeak = Get-EspeakNgCandidate
$plannedVenvCommand = if ($selectedPython.Found) {
    "`"$($selectedPython.Path)`" -m venv `"$kokoroVenvPath`""
} else {
    'Unavailable until a Python 3.11 runtime is selected'
}
$plannedInstallCommand = "`"$kokoroVenvPython`" -m pip install kokoro"
$venvExists = Test-Path -LiteralPath $kokoroVenvPython -PathType Leaf
$venvPythonVersion = if ($venvExists) { (& $kokoroVenvPython --version 2>&1 | Select-Object -First 1).ToString().Trim() } else { 'Not found' }
$kokoroPackageInstalled = $false
$kokoroPackageVersion = 'Not found'
if ($venvExists) {
    $kokoroPackageOutput = @(& $kokoroVenvPython -m pip show kokoro 2>&1)
    $kokoroPackageText = ($kokoroPackageOutput | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
    if ($LASTEXITCODE -eq 0 -and $kokoroPackageText -match '(?m)^Name:\s+kokoro\s*$') {
        $kokoroPackageInstalled = $true
        if ($kokoroPackageText -match '(?m)^Version:\s+(.+)$') {
            $kokoroPackageVersion = $matches[1]
        }
    }
}

Write-Host ""
Write-Host "RELAY KOKORO VENV SETUP" -ForegroundColor Magenta
Write-Host "Mode: $(if ($AllowSetup) { 'APPROVAL GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "Selected runtime" -ForegroundColor Cyan
Write-SetupLine -Label "Python 3.11 candidate" -Value $(if ($selectedPython.Found) { "$($selectedPython.Path) [$($selectedPython.Source)]" } else { 'None' })
Write-SetupLine -Label "Python version" -Value $selectedPython.Version
Write-SetupLine -Label "espeak-ng" -Value $(if ($espeak.Found) { "$($espeak.Path) [$($espeak.Source)]" } else { 'Missing' })
Write-SetupLine -Label "Current venv Python" -Value $(if ($venvExists) { "$kokoroVenvPython ($venvPythonVersion)" } else { 'Missing' })
Write-SetupLine -Label "Current kokoro package" -Value $(if ($kokoroPackageInstalled) { "Installed: kokoro $kokoroPackageVersion" } else { 'Missing' })
Write-Host ""
Write-Host "Planned paths" -ForegroundColor Cyan
Write-SetupLine -Label "Tool folder" -Value $kokoroToolsPath
Write-SetupLine -Label "Venv path" -Value $kokoroVenvPath
Write-SetupLine -Label "Planned pip install" -Value $plannedInstallCommand
Write-Host ""
Write-Host "Safety boundaries" -ForegroundColor Cyan
Write-Host "- No audio generation"
Write-Host "- No autoplay"
Write-Host "- No microphone/audio capture"
Write-Host "- No app/runtime TTS"
Write-Host "- No OpenClaw changes"
Write-Host "- No voice cloning or impersonation"

if (-not $AllowSetup) {
    Write-Host ""
    Write-Host "Dry-run only. Nothing was created or installed." -ForegroundColor Yellow
    Write-Host "To proceed later, rerun with -AllowSetup." -ForegroundColor Yellow
    return
}

if (-not $selectedPython.Found) {
    throw "Refusing Kokoro setup: no verified Python 3.11 runtime was selected."
}

if ($selectedPython.Version -notmatch '^Python 3\.11(\.|$)') {
    throw "Refusing Kokoro setup: selected runtime is not Python 3.11.x."
}

if (-not $espeak.Found) {
    throw "Refusing Kokoro setup: espeak-ng was not found."
}

if (-not (Test-Path -LiteralPath $kokoroToolsPath -PathType Container)) {
    New-Item -ItemType Directory -Path $kokoroToolsPath | Out-Null
}

if ((Test-Path -LiteralPath $kokoroVenvPath -PathType Container) -and -not $venvExists) {
    throw "Refusing to overwrite a malformed Kokoro venv directory: $kokoroVenvPath"
}

if (-not $venvExists) {
    Write-Host ""
    Write-Host "Creating Kokoro venv" -ForegroundColor Cyan
    Write-Host $plannedVenvCommand
    Invoke-CheckedCommand -FailureMessage "Kokoro venv creation failed." -Command {
        & $selectedPython.Path -m venv $kokoroVenvPath
    }
}
else {
    Write-Host ""
    Write-Host "Existing venv detected; reusing it." -ForegroundColor Cyan
}

if (-not (Test-Path -LiteralPath $kokoroVenvPython -PathType Leaf)) {
    throw "Kokoro venv Python was not created: $kokoroVenvPython"
}

$venvPythonVersion = (& $kokoroVenvPython --version 2>&1 | Select-Object -First 1).ToString().Trim()
if ($venvPythonVersion -notmatch '^Python 3\.11(\.|$)') {
    throw "Refusing to continue: Kokoro venv Python is not 3.11.x ($venvPythonVersion)"
}

Write-Host ""
Write-Host "Upgrading pip inside the venv" -ForegroundColor Cyan
Invoke-CheckedCommand -FailureMessage "pip upgrade failed." -Command {
    & $kokoroVenvPython -m pip install --upgrade pip
}

if ($SkipPackageInstall) {
    Write-Host ""
    Write-Host "Package install skipped by request." -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Installing Kokoro package" -ForegroundColor Cyan
    Write-Host $plannedInstallCommand
    Invoke-CheckedCommand -FailureMessage "Kokoro package install failed." -Command {
        & $kokoroVenvPython -m pip install kokoro
    }

    Write-Host ""
    Write-Host "Installed package check" -ForegroundColor Cyan
    & $kokoroVenvPython -m pip show kokoro
}

Write-Host ""
Write-Host "Setup summary" -ForegroundColor Cyan
Write-SetupLine -Label "Selected Python" -Value "$($selectedPython.Path) ($($selectedPython.Version))"
Write-SetupLine -Label "espeak-ng" -Value "$($espeak.Path) [$($espeak.Source)]"
Write-SetupLine -Label "Venv Python" -Value "$kokoroVenvPython ($venvPythonVersion)"
Write-SetupLine -Label "Kokoro package" -Value $(if ($SkipPackageInstall) { 'Not attempted' } elseif ($LASTEXITCODE -eq 0) { 'Installed or already present' } else { 'Install status unknown' })
Write-Host "- No audio was generated"
Write-Host "- No autoplay occurred"
Write-Host "- No microphone/audio capture occurred"
Write-Host "- No OpenClaw changes were made"
