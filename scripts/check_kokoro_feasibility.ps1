[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent $PSScriptRoot
$kokoroVenvPython = Join-Path $repoRoot "tools\kokoro.venv\Scripts\python.exe"
$kokoroCachePath = Join-Path $repoRoot "tools\kokoro\models"
$kokoroSetupScript = Join-Path $repoRoot "scripts\setup_kokoro_venv_gated.ps1"
$uvPythonRoot = Join-Path $env:APPDATA "uv\python"
$espeakFallbackPath = "C:\Program Files\eSpeak NG\espeak-ng.exe"

function Test-GitIgnoredPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    & git -C $repoRoot check-ignore -q -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
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
    $candidates = New-Object System.Collections.ArrayList
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

    $knownUvPython311 = Join-Path $env:APPDATA 'uv\python\cpython-3.11.15-windows-x86_64-none\python.exe'
    if (Test-Path -LiteralPath $knownUvPython311 -PathType Leaf) {
        [void]$candidates.Add([pscustomobject]@{
            Source = 'known uv path'
            Path = $knownUvPython311
        })
    }

    foreach ($candidate in $candidates) {
        $result = Invoke-OptionalExecutableCommand -Path $candidate.Path -Arguments @('--version')
        $version = ($result.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
        if ($result.Available -and $result.Success -and $version -match '^Python 3\.11(\.|$)') {
            return [pscustomobject]@{
                Found = $true
                Path = $candidate.Path
                Source = $candidate.Source
                Version = $version
            }
        }
    }

    return [pscustomobject]@{
        Found = $false
        Path = $null
        Source = 'none'
        Version = 'Not found'
    }
}

function Get-EspeakNgCandidate {
    $command = Get-Command espeak-ng -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) {
        return [pscustomobject]@{
            Found = $true
            Path = $command.Source
            Source = 'PATH'
        }
    }

    if (Test-Path -LiteralPath $espeakFallbackPath -PathType Leaf) {
        return [pscustomobject]@{
            Found = $true
            Path = $espeakFallbackPath
            Source = 'Program Files'
        }
    }

    return [pscustomobject]@{
        Found = $false
        Path = $null
        Source = 'missing'
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
            Version = 'Not found'
        }
    }

    try {
        $output = @(& $PythonPath -m pip show kokoro 2>&1)
        $text = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
        if ($LASTEXITCODE -eq 0 -and $text -match '(?m)^Name:\s+kokoro\s*$') {
            $version = 'Unknown'
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
        Version = 'Not found'
    }
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

$pythonCandidate = Get-Python311Candidate
$espeakCandidate = Get-EspeakNgCandidate
$kokoroPackageStatus = Get-KokoroPackageStatus -PythonPath $kokoroVenvPython
$kokoroVenvPresent = Test-Path -LiteralPath $kokoroVenvPython -PathType Leaf
$kokoroVenvVersion = if ($kokoroVenvPresent) { (& $kokoroVenvPython --version 2>&1 | Select-Object -First 1).ToString().Trim() } else { 'Not available' }
$kokoroCachePresent = Test-Path -LiteralPath $kokoroCachePath -PathType Container
$kokoroCacheFileCount = if ($kokoroCachePresent) { @(
    Get-ChildItem -LiteralPath $kokoroCachePath -Recurse -File -ErrorAction SilentlyContinue
).Count } else { 0 }
$kokoroFirstWavCount = if (Test-Path -LiteralPath (Join-Path $repoRoot 'outputs\tts_tests') -PathType Container) {
    @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'outputs\tts_tests') -Recurse -File -Filter 'relay_kokoro_first_*.wav' -ErrorAction SilentlyContinue
    ).Count
} else { 0 }
$kokoroLatestWav = Get-LatestFile -Folder (Join-Path $repoRoot 'outputs\tts_tests') -Filter 'relay_kokoro_first_*.wav'
$kokoroLatestWavPath = if ($null -ne $kokoroLatestWav) { $kokoroLatestWav.FullName } else { 'None' }
$kokoroSweepWavCount = if (Test-Path -LiteralPath (Join-Path $repoRoot 'outputs\tts_tests') -PathType Container) {
    @(
        Get-ChildItem -LiteralPath (Join-Path $repoRoot 'outputs\tts_tests') -Recurse -File -Filter 'relay_kokoro_sweep_*.wav' -ErrorAction SilentlyContinue
    ).Count
} else { 0 }
$kokoroLatestSweepWav = Get-LatestFile -Folder (Join-Path $repoRoot 'outputs\tts_tests') -Filter 'relay_kokoro_sweep_*.wav'
$kokoroLatestSweepWavPath = if ($null -ne $kokoroLatestSweepWav) { $kokoroLatestSweepWav.FullName } else { 'None' }
$ttsTestsPresent = Test-Path -LiteralPath (Join-Path $repoRoot 'outputs\tts_tests') -PathType Container
$ignoreChecks = [ordered]@{
    "tools/kokoro.venv/" = (Test-GitIgnoredPattern -Path "tools/kokoro.venv/")
    "tools/kokoro/models/" = (Test-GitIgnoredPattern -Path "tools/kokoro/models/")
    "outputs/tts_tests/*.wav" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.wav")
    "outputs/tts_tests/*.mp3" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.mp3")
}

$prerequisitesReady = $pythonCandidate.Found -and $espeakCandidate.Found -and $ttsTestsPresent -and
    $ignoreChecks["tools/kokoro.venv/"] -and $ignoreChecks["tools/kokoro/models/"] -and
    $ignoreChecks["outputs/tts_tests/*.wav"] -and $ignoreChecks["outputs/tts_tests/*.mp3"]

Write-Host ""
Write-Host "Relay Kokoro Feasibility Check" -ForegroundColor Magenta
Write-Host "Feasibility lane exists. Prerequisites are ready; future Kokoro work remains gated." -ForegroundColor DarkGray

Write-Host ""
Write-Host "Readiness summary" -ForegroundColor Cyan
Write-Host ("- Prerequisites ready: {0}" -f $(if ($prerequisitesReady) { "Yes" } else { "No" }))
Write-Host ("- Venv setup: {0}" -f $(if ($kokoroVenvPresent) { "Present" } else { "Pending" }))
Write-Host ("- Kokoro package: {0}" -f $(if ($kokoroPackageStatus.Installed) { "Installed ($($kokoroPackageStatus.Version))" } else { "Missing" }))
Write-Host ("- Kokoro cache: {0}" -f $(if ($kokoroCachePresent) { "Present ($kokoroCacheFileCount files)" } else { "Missing" }))
Write-Host ("- First WAV: {0}" -f $(if ($kokoroFirstWavCount -gt 0) { "Present ($kokoroFirstWavCount file(s))" } else { "Missing" }))
Write-Host ("- Comparison sweep: {0}" -f $(if ($kokoroSweepWavCount -gt 0) { "Present ($kokoroSweepWavCount file(s))" } else { "Missing" }))
Write-Host ("- Sweep runner: {0}" -f (Join-Path $repoRoot 'scripts\run_kokoro_voice_sweep_gated.ps1'))

Write-Host ""
Write-Host "Prerequisite prep lane" -ForegroundColor Cyan
Write-Host (Join-Path $repoRoot "scripts\check_kokoro_prereqs.ps1")
Write-Host "Run this before any future Kokoro model/test or package-review attempt."

Write-Host ""
Write-Host "Venv setup lane" -ForegroundColor Cyan
Write-Host $kokoroSetupScript
Write-Host "Run this with -AllowSetup only after explicit approval."

Write-Host ""
Write-Host "Kokoro status" -ForegroundColor Cyan
Write-Host "- Planning-only"
Write-Host "- Prefetch and first-WAV gates are available"
Write-Host "- No app/runtime TTS"
Write-Host "- No microphone/audio capture"
Write-Host "- No OpenClaw changes"
Write-Host ("- Latest first WAV: {0}" -f $kokoroLatestWavPath)
Write-Host ("- Latest sweep WAV: {0}" -f $kokoroLatestSweepWavPath)
