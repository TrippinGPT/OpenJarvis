[CmdletBinding()]
param(
    [switch]$AllowGenerate,
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
$piperRoot = Join-Path $repoRoot "tools\piper"
$localPython = Join-Path $piperRoot ".venv\Scripts\python.exe"
$modelsRoot = Join-Path $piperRoot "models"
$outputRoot = Join-Path $repoRoot "outputs\tts_tests"
$voiceConfigPath = Join-Path $repoRoot "config\relay_voice_profiles.json"

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

$defaultVoiceId = "Unavailable"
$defaultLine = $null
if (Test-Path -LiteralPath $voiceConfigPath -PathType Leaf) {
    try {
        $voiceConfig = Get-Content -LiteralPath $voiceConfigPath -Raw | ConvertFrom-Json
        $defaultVoiceId = [string]$voiceConfig.default_voice
        $defaultProfile = $voiceConfig.voices |
            Where-Object { $_.id -eq $defaultVoiceId } |
            Select-Object -First 1

        if ($null -ne $defaultProfile -and @($defaultProfile.do_say).Count -gt 0) {
            $defaultLine = [string]$defaultProfile.do_say[0]
        }
    }
    catch {
        throw "Relay voice profile config is invalid: $($_.Exception.Message)"
    }
}

$plannedLine = if (-not [string]::IsNullOrWhiteSpace($Line)) { $Line.Trim() } else { $defaultLine }
if ([string]::IsNullOrWhiteSpace($plannedLine)) {
    throw "No Relay test line was provided or found in config/relay_voice_profiles.json."
}
if ($plannedLine.Length -gt 500) {
    throw "Relay test line is limited to 500 characters."
}

$localModuleAvailable = Test-PiperModule -PythonPath $localPython
$piperCommand = Get-Command "piper" -ErrorAction SilentlyContinue | Select-Object -First 1
$piperDetected = $localModuleAvailable -or ($null -ne $piperCommand)
$models = @()
if (Test-Path -LiteralPath $modelsRoot -PathType Container) {
    $models = @(
        Get-ChildItem -LiteralPath $modelsRoot -Recurse -File -Filter "*.onnx" |
            Sort-Object FullName
    )
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$plannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot "relay-smartmouth-$timestamp.wav")

Write-Host ""
Write-Host "Relay Piper Gated Test Line" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowGenerate) { 'GENERATION GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Planned test" -ForegroundColor Cyan
Write-Host "- Voice profile: $defaultVoiceId"
Write-Host "- Test line: $plannedLine"
Write-Host "- Planned output: $plannedOutput"
Write-Host "- Piper detected: $piperDetected"
Write-Host "- Relay-local Piper module: $localModuleAvailable"
Write-Host "- Local ONNX models found: $($models.Count)"
Write-Host "- Auto-play: disabled"
Write-Host ""

if (-not $AllowGenerate) {
    Write-Host "Dry run complete. Audio generation requires -AllowGenerate." -ForegroundColor Yellow
}
elseif (-not $localModuleAvailable) {
    Write-Host "Generation stopped: the Relay-local Piper module was not detected at tools\piper\.venv." -ForegroundColor Yellow
    Write-Host "Run the gated install review after a compatible local Python interpreter is approved." -ForegroundColor Yellow
}
elseif ($models.Count -eq 0) {
    Write-Host "Voice model missing. Manual model selection/download requires a future explicit approval step." -ForegroundColor Yellow
}
elseif ($models.Count -gt 1) {
    Write-Host "Generation stopped: multiple voice models were found." -ForegroundColor Yellow
    Write-Host "A future approved task must select one reviewed model explicitly." -ForegroundColor Yellow
}
elseif (-not (Test-Path -LiteralPath "$($models[0].FullName).json" -PathType Leaf)) {
    Write-Host "Voice model config missing: $($models[0].FullName).json" -ForegroundColor Yellow
    Write-Host "Manual model selection/download requires a future explicit approval step." -ForegroundColor Yellow
}
elseif (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    Write-Host "Generation stopped: output sandbox is missing." -ForegroundColor Yellow
    Write-Host "Run scripts\prepare_piper_sandbox.ps1 first." -ForegroundColor Yellow
}
else {
    $model = $models[0]
    $modelName = [System.IO.Path]::GetFileNameWithoutExtension($model.Name)
    $modelDataDir = $model.DirectoryName

    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "PIPER AUDIO GENERATION APPROVED BY -AllowGenerate" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "Command: $localPython -m piper -m $modelName --data-dir `"$modelDataDir`" -f `"$plannedOutput`" -- <approved Relay line>"
    Write-Host "No playback command will run."
    Write-Host ""

    & $localPython -m piper -m $modelName --data-dir $modelDataDir -f $plannedOutput -- $plannedLine
    if ($LASTEXITCODE -ne 0) {
        throw "Piper exited with code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $plannedOutput -PathType Leaf)) {
        throw "Piper reported success but the expected output was not created: $plannedOutput"
    }

    Write-Host "Audio generated: $plannedOutput" -ForegroundColor Green
    Write-Host "Audio was not played." -ForegroundColor Green
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No model download attempted"
Write-Host "- No audio playback attempted"
Write-Host "- No microphone/audio capture used"
Write-Host "- No voice cloning or impersonation requested"
Write-Host "- OpenClaw was not touched"
