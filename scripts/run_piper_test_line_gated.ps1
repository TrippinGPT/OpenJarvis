[CmdletBinding()]
param(
    [switch]$AllowGenerate,
    [string]$VoiceId = "en_US_lessac_medium",
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
$voiceConfigPath = Join-Path $repoRoot "config\piper_voice_models.json"
$relayVoiceProfilePath = Join-Path $repoRoot "config\relay_voice_profiles.json"
$localVenvPath = Join-Path $repoRoot "tools\piper.venv"
$localPython = Join-Path $localVenvPath "Scripts\python.exe"
$voicesRoot = Join-Path $repoRoot "tools\piper\voices"
$outputRoot = Join-Path $repoRoot "outputs\tts_tests"

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to run Piper outside the expected Relay repo: $expectedRepoRoot"
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

function Get-VoiceConfig {
    if (-not (Test-Path -LiteralPath $voiceConfigPath -PathType Leaf)) {
        throw "Missing voice-model config: $voiceConfigPath"
    }

    try {
        return Get-Content -LiteralPath $voiceConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Voice-model config is invalid: $($_.Exception.Message)"
    }
}

function Get-SelectedVoice {
    param(
        [Parameter(Mandatory = $true)]
        $Config,

        [Parameter(Mandatory = $true)]
        [string]$RequestedVoiceId
    )

    $selectedVoice = $Config.voices |
        Where-Object { $_.id -eq $RequestedVoiceId } |
        Select-Object -First 1

    if ($null -eq $selectedVoice) {
        throw "VoiceId '$RequestedVoiceId' was not found in $voiceConfigPath."
    }

    return $selectedVoice
}

function Get-SmartmouthLine {
    if (-not (Test-Path -LiteralPath $relayVoiceProfilePath -PathType Leaf)) {
        return [pscustomobject]@{
            Line = $null
            Source = "fallback"
        }
    }

    try {
        $relayProfiles = Get-Content -LiteralPath $relayVoiceProfilePath -Raw | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Line = $null
            Source = "fallback"
        }
    }

    $defaultProfileId = $null
    if ($relayProfiles.PSObject.Properties.Name -contains "default_voice") {
        $defaultProfileId = [string]$relayProfiles.default_voice
    }
    elseif ($relayProfiles.PSObject.Properties.Name -contains "default_voice_id") {
        $defaultProfileId = [string]$relayProfiles.default_voice_id
    }

    if ([string]::IsNullOrWhiteSpace($defaultProfileId)) {
        $defaultProfileId = "smartmouth_relay"
    }

    $profile = $relayProfiles.voices |
        Where-Object { $_.id -eq $defaultProfileId } |
        Select-Object -First 1
    if ($null -eq $profile) {
        $profile = $relayProfiles.voices |
            Where-Object { $_.id -eq "smartmouth_relay" } |
            Select-Object -First 1
    }

    if ($null -eq $profile -or @($profile.do_say).Count -eq 0) {
        return [pscustomobject]@{
            Line = $null
            Source = "fallback"
        }
    }

    return [pscustomobject]@{
        Line = [string]$profile.do_say[0]
        Source = "config\relay_voice_profiles.json:$($profile.id)"
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

function Format-FileSize {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path
    return ("{0:N0} bytes" -f $item.Length)
}

$voiceConfig = Get-VoiceConfig
$selectedVoice = Get-SelectedVoice -Config $voiceConfig -RequestedVoiceId $VoiceId
$lineSelection = if (-not [string]::IsNullOrWhiteSpace($Line)) {
    [pscustomobject]@{
        Line = $Line.Trim()
        Source = "command line"
    }
}
else {
    Get-SmartmouthLine
}

$selectedLine = $lineSelection.Line
if ([string]::IsNullOrWhiteSpace($selectedLine)) {
    $selectedLine = "Relay online. Try not to break anything expensive."
    $lineSelection = [pscustomobject]@{
        Line = $selectedLine
        Source = "fallback"
    }
}

$modelPath = Assert-RelayPath -Path $selectedVoice.model_output_path
$configOutputPath = Assert-RelayPath -Path $selectedVoice.config_output_path
$modelExists = Test-Path -LiteralPath $modelPath -PathType Leaf
$configExists = Test-Path -LiteralPath $configOutputPath -PathType Leaf
$voiceFolderExists = Test-Path -LiteralPath $voicesRoot -PathType Container
$voiceModelCount = Get-Count -Folder $voicesRoot -Filter "*.onnx"
$voiceConfigCount = Get-Count -Folder $voicesRoot -Filter "*.onnx.json"
$localPiperInstalled = Test-PiperModule -PythonPath $localPython
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$plannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot "relay_test_smartmouth_$timestamp.wav")

Write-Host ""
Write-Host "Relay Piper Gated Test WAV" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowGenerate) { 'GENERATION GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Selected voice" -ForegroundColor Cyan
Write-Host "- id: $($selectedVoice.id)"
Write-Host "- display name: $($selectedVoice.display_name)"
Write-Host "- language: $($selectedVoice.language)"
Write-Host "- quality: $($selectedVoice.quality)"
Write-Host "- model output path: $modelPath"
Write-Host "- config output path: $configOutputPath"
Write-Host "- model present: $modelExists"
Write-Host "- config present: $configExists"
Write-Host "- voice folder present: $voiceFolderExists"
Write-Host "- .onnx count: $voiceModelCount"
Write-Host "- .onnx.json count: $voiceConfigCount"
Write-Host ""

Write-Host "Selected line" -ForegroundColor Cyan
Write-Host "- source: $($lineSelection.Source)"
Write-Host "- text: $selectedLine"
Write-Host "- planned output: $plannedOutput"
Write-Host "- generation requires -AllowGenerate"
Write-Host ""

if (-not $AllowGenerate) {
    Write-Host "Dry run complete. No audio was generated." -ForegroundColor Yellow
    Write-Host "No playback occurred."
    Write-Host "No microphone access occurred."
    Write-Host "No app runtime TTS was added."
    Write-Host "OpenClaw was not touched."
    return
}

if (-not $modelExists -or -not $configExists) {
    throw "Approved Piper voice model files are missing. Run the gated voice-model download first."
}

if (-not $localPiperInstalled) {
    throw "Piper is not available in the local Relay venv: $localPython"
}

if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $outputRoot | Out-Null
}

if (Test-Path -LiteralPath $plannedOutput -PathType Leaf) {
    throw "Planned output already exists: $plannedOutput"
}

$modelName = [System.IO.Path]::GetFileNameWithoutExtension($selectedVoice.model_filename)
$piperArgs = @(
    '-m', 'piper',
    '-m', $modelName,
    '--data-dir', $voicesRoot,
    '-f', $plannedOutput,
    '--',
    $selectedLine
)

Write-Host ""
Write-Host "Piper invocation" -ForegroundColor Cyan
Write-Host ("{0} -m piper -m {1} --data-dir {2} -f {3} -- <approved line>" -f $localPython, $modelName, $voicesRoot, $plannedOutput)
Write-Host "No playback command will run."
Write-Host ""

& $localPython @piperArgs
if ($LASTEXITCODE -ne 0) {
    throw "Piper exited with code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $plannedOutput -PathType Leaf)) {
    throw "Piper reported success but the expected WAV was not created: $plannedOutput"
}

$generatedFile = Get-Item -LiteralPath $plannedOutput

Write-Host ""
Write-Host "Generation result" -ForegroundColor Green
Write-Host "- Output WAV: $plannedOutput"
Write-Host "- File size: $($generatedFile.Length) bytes"
Write-Host "- No playback occurred."
Write-Host "- No microphone access occurred."
Write-Host "- No app runtime TTS was added."
Write-Host "- OpenClaw was not touched."

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No autoplay"
Write-Host "- No browser shell execution"
Write-Host "- No voice cloning or impersonation requested"
