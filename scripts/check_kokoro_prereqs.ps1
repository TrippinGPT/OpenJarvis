[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent $PSScriptRoot
$kokoroPrereqsPath = Join-Path $repoRoot "docs\RELAY_KOKORO_PREREQUISITES.md"
$ttsPlanPath = Join-Path $repoRoot "docs\RELAY_TTS_PLAN.md"
$kokoroPlanPath = Join-Path $repoRoot "docs\RELAY_KOKORO_TTS_PLAN.md"
$voiceProfilesPath = Join-Path $repoRoot "config\relay_voice_profiles.json"
$kokoroToolsPath = Join-Path $repoRoot "tools\kokoro"
$kokoroVenvPath = Join-Path $repoRoot "tools\kokoro.venv"
$ttsTestsPath = Join-Path $repoRoot "outputs\tts_tests"

function Write-CheckLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-36} {1}" -f "${Label}:", $Value)
}

function Invoke-PyCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $pyCommand = Get-Command py -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $pyCommand) {
        return [pscustomobject]@{
            Available = $false
            Output = @("py launcher not available")
            Success = $false
        }
    }

    $output = & $pyCommand.Source @Arguments 2>&1
    $success = ($LASTEXITCODE -eq 0)
    return [pscustomobject]@{
        Available = $true
        Output = @($output)
        Success = $success
    }
}

function Get-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{
            Available = $false
            Path = "Not found"
            Version = "Not found"
        }
    }

    $version = & $command.Source --version 2>&1 | Select-Object -First 1
    $versionText = if ($null -ne $version -and -not [string]::IsNullOrWhiteSpace("$version")) { "$version".Trim() } else { "Available" }
    return [pscustomobject]@{
        Available = $true
        Path = $command.Source
        Version = $versionText
    }
}

function Test-GitIgnoredPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    & git -C $repoRoot check-ignore -q -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Get-EspeakNgInfo {
    $command = Get-Command espeak-ng -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{
            Available = $false
            Path = "Not found"
            Version = "Not found"
        }
    }

    $version = & $command.Source --version 2>&1 | Select-Object -First 1
    $versionText = if ($null -ne $version -and -not [string]::IsNullOrWhiteSpace("$version")) { "$version".Trim() } else { "Available" }
    return [pscustomobject]@{
        Available = $true
        Path = $command.Source
        Version = $versionText
    }
}

$python = Get-CommandVersion -Name "python"
$uv = Get-CommandVersion -Name "uv"
$pip = Get-CommandVersion -Name "pip"
$pyInventory = $null
try {
    $pyInventory = & py -0p 2>&1
}
catch {
    $pyInventory = @("py launcher check failed: $($_.Exception.Message)")
}

$py311Version = Invoke-PyCommand -Arguments @("-3.11", "--version")
$py311Executable = Invoke-PyCommand -Arguments @("-3.11", "-c", "import sys; print(sys.executable)")
$py312Version = Invoke-PyCommand -Arguments @("-3.12", "--version")
$py312Executable = Invoke-PyCommand -Arguments @("-3.12", "-c", "import sys; print(sys.executable)")
$espeakNg = Get-EspeakNgInfo

$ignoreChecks = [ordered]@{
    "tools/kokoro.venv/" = (Test-GitIgnoredPattern -Path "tools/kokoro.venv/")
    "tools/kokoro/models/" = (Test-GitIgnoredPattern -Path "tools/kokoro/models/")
    "outputs/tts_tests/*.wav" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.wav")
    "outputs/tts_tests/*.mp3" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.mp3")
}

$kokoroToolsExists = Test-Path -LiteralPath $kokoroToolsPath -PathType Container
$kokoroVenvExists = Test-Path -LiteralPath $kokoroVenvPath -PathType Container
$ttsTestsExists = Test-Path -LiteralPath $ttsTestsPath -PathType Container
$defaultPythonPath = if ($python.Available) { $python.Path } else { "Not found" }
$defaultPythonVersion = if ($python.Available) { $python.Version } else { "Not found" }
$missingPrerequisites = @()

if (-not $python.Available) { $missingPrerequisites += "default Python" }
if (-not $uv.Available) { $missingPrerequisites += "uv" }
if (-not $pip.Available) { $missingPrerequisites += "pip" }
if (-not $py311Version.Success) { $missingPrerequisites += "Python 3.11" }
if (-not $espeakNg.Available) { $missingPrerequisites += "espeak-ng" }
if (-not $ttsTestsExists) { $missingPrerequisites += "outputs\\tts_tests" }
if (-not $ignoreChecks["tools/kokoro.venv/"]) { $missingPrerequisites += "tools\\kokoro.venv ignore rule" }
if (-not $ignoreChecks["tools/kokoro/models/"]) { $missingPrerequisites += "tools\\kokoro\\models ignore rule" }
if (-not $ignoreChecks["outputs/tts_tests/*.wav"]) { $missingPrerequisites += "WAV ignore rule" }
if (-not $ignoreChecks["outputs/tts_tests/*.mp3"]) { $missingPrerequisites += "MP3 ignore rule" }

Write-Host ""
Write-Host "RELAY KOKORO PREREQUISITE CHECK" -ForegroundColor Magenta
Write-Host "Read-only prep check. No install, no download, no audio." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Environment" -ForegroundColor Cyan
Write-CheckLine -Label "Checked at" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
Write-CheckLine -Label "Repo root" -Value $repoRoot
Write-CheckLine -Label "OS info" -Value ([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)
Write-CheckLine -Label "PowerShell" -Value $PSVersionTable.PSVersion.ToString()
Write-CheckLine -Label "Default Python version" -Value $defaultPythonVersion
Write-CheckLine -Label "Default Python path" -Value $defaultPythonPath
Write-CheckLine -Label "uv" -Value $(if ($uv.Available) { $uv.Version } else { "Not found" })
Write-CheckLine -Label "pip" -Value $(if ($pip.Available) { $pip.Version } else { "Not found" })

Write-Host ""
Write-Host "Python launcher" -ForegroundColor Cyan
if ($pyInventory -is [array]) {
    foreach ($line in $pyInventory) {
        if ($null -ne $line -and -not [string]::IsNullOrWhiteSpace("$line")) {
            Write-Host "  $line"
        }
    }
}
else {
    Write-Host "  $pyInventory"
}
Write-CheckLine -Label "Python 3.11 --version" -Value $(if ($py311Version.Output.Count -gt 0) { $py311Version.Output -join " " } else { "Not found" })
Write-CheckLine -Label "Python 3.11 executable" -Value $(if ($py311Executable.Output.Count -gt 0) { $py311Executable.Output -join " " } else { "Not found" })
Write-CheckLine -Label "Python 3.12 --version" -Value $(if ($py312Version.Output.Count -gt 0) { $py312Version.Output -join " " } else { "Not found" })
Write-CheckLine -Label "Python 3.12 executable" -Value $(if ($py312Executable.Output.Count -gt 0) { $py312Executable.Output -join " " } else { "Not found" })

Write-Host ""
Write-Host "Kokoro local paths" -ForegroundColor Cyan
Write-CheckLine -Label "tools\kokoro" -Value $(if ($kokoroToolsExists) { "Present: $kokoroToolsPath" } else { "Missing" })
Write-CheckLine -Label "tools\kokoro.venv" -Value $(if ($kokoroVenvExists) { "Present: $kokoroVenvPath" } else { "Missing" })
Write-CheckLine -Label "outputs\tts_tests" -Value $(if ($ttsTestsExists) { "Present: $ttsTestsPath" } else { "Missing" })

Write-Host ""
Write-Host "espeak-ng" -ForegroundColor Cyan
Write-CheckLine -Label "Available" -Value $(if ($espeakNg.Available) { "Yes" } else { "No" })
Write-CheckLine -Label "Path" -Value $espeakNg.Path
Write-CheckLine -Label "Version" -Value $espeakNg.Version

Write-Host ""
Write-Host "Git ignore readiness" -ForegroundColor Cyan
foreach ($item in $ignoreChecks.GetEnumerator()) {
    Write-CheckLine -Label $item.Key -Value $(if ($item.Value) { "Covered" } else { "Not covered" })
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No folders created"
Write-Host "- No packages installed"
Write-Host "- No models downloaded"
Write-Host "- No audio generated"
Write-Host "- No audio played"
Write-Host "- No microphone/audio capture used"
Write-Host "- No remote APIs called"
Write-Host "- No OpenClaw changes made"

Write-Host ""
if ($missingPrerequisites.Count -eq 0) {
    Write-Host "Summary: Ready for future gated setup" -ForegroundColor Green
}
else {
    Write-Host "Summary: Blocked by missing prerequisites" -ForegroundColor Yellow
    Write-Host ("Missing: {0}" -f ($missingPrerequisites -join ", ")) -ForegroundColor Yellow
}
