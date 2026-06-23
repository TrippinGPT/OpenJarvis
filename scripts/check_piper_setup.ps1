[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$voiceConfigPath = Join-Path $repoRoot "config\relay_voice_profiles.json"
$plannedPiperPath = Join-Path $repoRoot "tools\piper"
$plannedOutputPath = Join-Path $repoRoot "outputs\tts_tests"
$localVenvPath = Join-Path $repoRoot "tools\piper.venv"
$localPython = Join-Path $localVenvPath "Scripts\python.exe"
$localPiperCommand = Join-Path $localVenvPath "Scripts\piper.exe"
$modelsPath = Join-Path $plannedPiperPath "models"

function Get-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{
            Available = $false
            Version = "Not found"
        }
    }

    try {
        $output = & $command.Source --version 2>&1
        $version = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join " "
        if ([string]::IsNullOrWhiteSpace($version)) {
            $version = "Available (version not reported)"
        }
    }
    catch {
        $version = "Available (version check failed: $($_.Exception.Message))"
    }

    return [pscustomobject]@{
        Available = $true
        Version = $version
    }
}

function Get-PathStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return "Present"
    }

    return "Missing, expected before setup."
}

function Write-CheckLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-30} {1}" -f "${Label}:", $Value)
}

$python = Get-CommandVersion -Name "python"
$uv = Get-CommandVersion -Name "uv"
$piperCommand = Get-Command "piper" -ErrorAction SilentlyContinue | Select-Object -First 1
$localPiperInstalled = $false
$localPiperVersion = "Not installed"

if (Test-Path -LiteralPath $localPython -PathType Leaf) {
    & $localPython -c "import piper" 2>$null
    $localPiperInstalled = ($LASTEXITCODE -eq 0)
    if ($localPiperInstalled) {
        $localPiperVersion = (& $localPython -c "from importlib.metadata import version; print(version('piper-tts'))" 2>$null | Select-Object -First 1).ToString()
    }
}

$voiceModels = @()
if (Test-Path -LiteralPath $modelsPath -PathType Container) {
    $voiceModels = @(Get-ChildItem -LiteralPath $modelsPath -Recurse -File -Filter "*.onnx")
}

$configExists = Test-Path -LiteralPath $voiceConfigPath -PathType Leaf
$configValid = $false
$defaultVoiceId = "Unavailable"
$plannedFirstLine = "Unavailable"

if ($configExists) {
    try {
        $voiceConfig = Get-Content -LiteralPath $voiceConfigPath -Raw | ConvertFrom-Json
        $configValid = $true
        $defaultVoiceId = [string]$voiceConfig.default_voice
        $defaultProfile = $voiceConfig.voices |
            Where-Object { $_.id -eq $defaultVoiceId } |
            Select-Object -First 1

        if ($null -ne $defaultProfile -and @($defaultProfile.do_say).Count -gt 0) {
            $plannedFirstLine = [string]$defaultProfile.do_say[0]
        }
    }
    catch {
        $defaultVoiceId = "Config invalid: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Relay Piper Setup Check" -ForegroundColor Magenta
Write-Host "Read-only checklist. Piper will not be installed or executed." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Environment" -ForegroundColor Cyan
Write-CheckLine -Label "Checked at" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
Write-CheckLine -Label "Repo root" -Value $repoRoot
Write-CheckLine -Label "PowerShell" -Value $PSVersionTable.PSVersion.ToString()
Write-CheckLine -Label "Python" -Value $python.Version
Write-CheckLine -Label "uv" -Value $uv.Version

Write-Host ""
Write-Host "Piper planning state" -ForegroundColor Cyan
if ($null -ne $piperCommand) {
    Write-CheckLine -Label "Global Piper command" -Value "Available at $($piperCommand.Source)"
}
else {
    Write-CheckLine -Label "Global Piper command" -Value "Not installed (expected; Relay uses the local venv)"
}
Write-CheckLine -Label "Planned Piper folder" -Value (Get-PathStatus -Path $plannedPiperPath)
Write-CheckLine -Label "Piper folder path" -Value $plannedPiperPath
Write-CheckLine -Label "Output test folder" -Value (Get-PathStatus -Path $plannedOutputPath)
Write-CheckLine -Label "Output folder path" -Value $plannedOutputPath
Write-CheckLine -Label "Local Piper venv" -Value (Get-PathStatus -Path $localVenvPath)
Write-CheckLine -Label "Local venv Python" -Value $(if (Test-Path -LiteralPath $localPython -PathType Leaf) { (& $localPython --version 2>&1 | Select-Object -First 1).ToString() } else { "Not found" })
Write-CheckLine -Label "Local Piper package" -Value $(if ($localPiperInstalled) { "Installed: $localPiperVersion" } else { "Not installed" })
Write-CheckLine -Label "Local Piper command" -Value $(if (Test-Path -LiteralPath $localPiperCommand -PathType Leaf) { $localPiperCommand } else { "Not found" })
Write-CheckLine -Label "Voice models" -Value $(if ($voiceModels.Count -gt 0) { "$($voiceModels.Count) found" } else { "Missing, expected before next step." })

Write-Host ""
Write-Host "Relay voice profile" -ForegroundColor Cyan
Write-CheckLine -Label "Voice config exists" -Value $configExists.ToString()
Write-CheckLine -Label "Voice config valid" -Value $configValid.ToString()
Write-CheckLine -Label "Default voice profile" -Value $defaultVoiceId
Write-CheckLine -Label "Planned first line" -Value $plannedFirstLine

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No folders created"
Write-Host "- No packages installed"
Write-Host "- No models downloaded"
Write-Host "- No audio generated or played"
Write-Host "- No microphone/audio capture used"
Write-Host "- No files modified"
Write-Host "- No OpenClaw modifications made"

Write-Host ""
if ($localPiperInstalled -and $voiceModels.Count -eq 0) {
    Write-Host "Status: Piper is installed in the Relay-local venv. Voice model missing, expected before next step." -ForegroundColor Green
}
elseif ($localPiperInstalled) {
    Write-Host "Status: Piper is installed locally and voice model files are present for review." -ForegroundColor Green
}
else {
    Write-Host "Status: Piper is not installed in the Relay-local venv." -ForegroundColor Yellow
}
