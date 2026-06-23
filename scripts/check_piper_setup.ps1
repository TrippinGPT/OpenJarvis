[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$voiceConfigPath = Join-Path $repoRoot "config\piper_voice_models.json"
$voiceFolderPath = Join-Path $repoRoot "tools\piper\voices"
$plannedOutputPath = Join-Path $repoRoot "outputs\tts_tests"
$localVenvPath = Join-Path $repoRoot "tools\piper.venv"
$localPython = Join-Path $localVenvPath "Scripts\python.exe"
$localPiperCommand = Join-Path $localVenvPath "Scripts\piper.exe"

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
        Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter $Filter
    ).Count
}

function Write-CheckLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-34} {1}" -f "${Label}:", $Value)
}

function Test-GitIgnoredPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    & git -C $repoRoot check-ignore -q -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
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

$voiceConfig = $null
$configExists = Test-Path -LiteralPath $voiceConfigPath -PathType Leaf
$configValid = $false
$defaultVoiceId = "Unavailable"
$defaultVoice = $null

if ($configExists) {
    try {
        $voiceConfig = Get-Content -LiteralPath $voiceConfigPath -Raw | ConvertFrom-Json
        $configValid = $true
        $defaultVoiceId = [string]$voiceConfig.default_voice_id
        $defaultVoice = $voiceConfig.voices |
            Where-Object { $_.id -eq $defaultVoiceId } |
            Select-Object -First 1
    }
    catch {
        $defaultVoiceId = "Config invalid: $($_.Exception.Message)"
    }
}

$voiceFolderExists = Test-Path -LiteralPath $voiceFolderPath -PathType Container
$voiceModelCount = Get-Count -Folder $voiceFolderPath -Filter "*.onnx"
$voiceConfigCount = Get-Count -Folder $voiceFolderPath -Filter "*.onnx.json"
$generatedWavs = @()
if (Test-Path -LiteralPath $plannedOutputPath -PathType Container) {
    $generatedWavs = @(
        Get-ChildItem -LiteralPath $plannedOutputPath -Recurse -File -Filter "*.wav" |
            Sort-Object LastWriteTime, FullName
    )
}
$generatedWavCount = $generatedWavs.Count
$latestGeneratedWav = $null
if ($generatedWavCount -gt 0) {
    $latestGeneratedWav = $generatedWavs |
        Sort-Object -Property @{ Expression = "LastWriteTime"; Descending = $true }, "FullName" |
        Select-Object -First 1
}
$ignoreProbePath = if ($null -ne $latestGeneratedWav) {
    $latestGeneratedWav.FullName
}
else {
    Join-Path $plannedOutputPath "relay_test_smartmouth_probe.wav"
}
$generatedAudioIgnoredByGit = Test-GitIgnoredPath -Path $ignoreProbePath

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
Write-Host "Piper runtime" -ForegroundColor Cyan
Write-CheckLine -Label "Piper venv path" -Value $localVenvPath
Write-CheckLine -Label "Piper installed" -Value $(if ($localPiperInstalled) { "Installed: $localPiperVersion" } else { "Missing" })
Write-CheckLine -Label "Local Piper command" -Value $(if (Test-Path -LiteralPath $localPiperCommand -PathType Leaf) { $localPiperCommand } else { "Missing" })
Write-CheckLine -Label "Global Piper command" -Value $(if ($null -ne $piperCommand) { $piperCommand.Source } else { "Not installed" })

Write-Host ""
Write-Host "Voice model gate" -ForegroundColor Cyan
Write-CheckLine -Label "Voice config exists" -Value $configExists.ToString()
Write-CheckLine -Label "Voice config valid" -Value $configValid.ToString()
Write-CheckLine -Label "Voice folder" -Value $(if ($voiceFolderExists) { "Present" } else { "Missing, expected before setup." })
Write-CheckLine -Label "Voice folder path" -Value $voiceFolderPath
Write-CheckLine -Label ".onnx count" -Value $voiceModelCount.ToString()
Write-CheckLine -Label ".onnx.json count" -Value $voiceConfigCount.ToString()
Write-CheckLine -Label "Default voice id" -Value $defaultVoiceId
Write-CheckLine -Label "Selected model_output_path" -Value $(if ($null -ne $defaultVoice) { if (Test-Path -LiteralPath $defaultVoice.model_output_path -PathType Leaf) { "Present" } else { "Missing, expected before download." } } else { "Unavailable" })
Write-CheckLine -Label "Selected config_output_path" -Value $(if ($null -ne $defaultVoice) { if (Test-Path -LiteralPath $defaultVoice.config_output_path -PathType Leaf) { "Present" } else { "Missing, expected before download." } } else { "Unavailable" })

Write-Host ""
Write-Host "Generated audio" -ForegroundColor Cyan
Write-CheckLine -Label "WAV count" -Value $generatedWavCount.ToString()
Write-CheckLine -Label "Latest generated WAV" -Value $(if ($null -ne $latestGeneratedWav) { $latestGeneratedWav.FullName } else { "None" })
Write-CheckLine -Label "Generated WAVs ignored by Git" -Value $(if ($generatedAudioIgnoredByGit) { "Yes" } else { "No" })

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
if ($localPiperInstalled) {
    Write-Host "Status: Piper is installed locally. Voice model review remains gated." -ForegroundColor Green
}
else {
    Write-Host "Status: Piper is missing from the local Relay venv." -ForegroundColor Yellow
}
