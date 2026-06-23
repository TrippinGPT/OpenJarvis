[CmdletBinding()]
param(
    [switch]$AllowGenerate,
    [string]$Line,
    [switch]$UseDefaultLineSet,
    [double]$LengthScale
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
$outputRoot = Join-Path $repoRoot "outputs\tts_tests"
$voicesRoot = Join-Path $repoRoot "tools\piper\voices"
$localPython = Join-Path $repoRoot "tools\piper.venv\Scripts\python.exe"

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

function Get-VoiceById {
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

function Get-DefaultLineSet {
    return @(
        "Relay online. Try not to break anything expensive.",
        "Routing that now. Shocking development: we are using a plan.",
        "Patch can touch the repo. Redline gets to yell if it gets stupid.",
        "I can make this faster, cleaner, and less cursed."
    )
}

function Resolve-LineSet {
    if (-not [string]::IsNullOrWhiteSpace($Line)) {
        return @($Line.Trim())
    }

    if ($UseDefaultLineSet) {
        return @(Get-DefaultLineSet)
    }

    return @(Get-DefaultLineSet)
}

function Get-FileSizeText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return ("{0:N0} bytes" -f (Get-Item -LiteralPath $Path).Length)
}

$voiceConfig = Get-VoiceConfig
$amyVoice = Get-VoiceById -Config $voiceConfig -RequestedVoiceId "en_US_amy_medium"
$modelPath = Assert-RelayPath -Path $amyVoice.model_output_path
$configPath = Assert-RelayPath -Path $amyVoice.config_output_path
$modelExists = Test-Path -LiteralPath $modelPath -PathType Leaf
$configExists = Test-Path -LiteralPath $configPath -PathType Leaf
$localPythonExists = Test-Path -LiteralPath $localPython -PathType Leaf
$lineSet = Resolve-LineSet
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$plannedOutputs = @()
for ($index = 0; $index -lt $lineSet.Count; $index++) {
    $lineNumber = $index + 1
    $plannedOutputs += [pscustomobject]@{
        Index = $lineNumber
        Line = [string]$lineSet[$index]
        OutputPath = Assert-RelayPath -Path (Join-Path $outputRoot ("relay_amy_tune_{0:D2}_{1}.wav" -f $lineNumber, $timestamp))
    }
}

Write-Host ""
Write-Host "Relay Piper Amy Tuning" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowGenerate) { 'GENERATION GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Selected voice" -ForegroundColor Cyan
Write-Host "- id: $($amyVoice.id)"
Write-Host "- display name: $($amyVoice.display_name)"
Write-Host "- review status: $($amyVoice.review_status)"
Write-Host "- relay fit: $($amyVoice.relay_fit)"
Write-Host "- technical status: $($amyVoice.technical_status)"
Write-Host "- model output path: $modelPath"
Write-Host "- config output path: $configPath"
Write-Host "- model present: $modelExists"
Write-Host "- config present: $configExists"
Write-Host "- local Piper Python: $(if ($localPythonExists) { $localPython } else { 'Missing' })"
Write-Host ""

Write-Host "Planned test lines" -ForegroundColor Cyan
foreach ($plan in $plannedOutputs) {
    Write-Host ("- {0:D2}: {1}" -f $plan.Index, $plan.Line)
    Write-Host ("  planned output: {0}" -f $plan.OutputPath)
}
Write-Host ""
Write-Host "Planned output folder: $outputRoot" -ForegroundColor Cyan
Write-Host "Generation requires -AllowGenerate." -ForegroundColor Yellow
Write-Host "No autoplay will occur." -ForegroundColor Yellow
Write-Host "No microphone/audio capture will occur." -ForegroundColor Yellow
Write-Host "No runtime TTS will be added." -ForegroundColor Yellow
Write-Host "No OpenClaw changes will be made." -ForegroundColor Yellow

if (-not $AllowGenerate) {
    Write-Host ""
    Write-Host "Dry run complete. No audio was generated." -ForegroundColor Yellow
    return
}

if (-not $modelExists -or -not $configExists) {
    throw "Amy voice model files are missing. Refusing to generate tuning WAVs."
}

if (-not $localPythonExists) {
    throw "Piper is not available in the local Relay venv: $localPython"
}

if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $outputRoot | Out-Null
}

Write-Host ""
Write-Host "Generation phase" -ForegroundColor Cyan
foreach ($plan in $plannedOutputs) {
    if (Test-Path -LiteralPath $plan.OutputPath -PathType Leaf) {
        throw "Planned output already exists: $($plan.OutputPath)"
    }

    $piperArgs = @(
        '-m', 'piper',
        '-m', $modelPath,
        '-c', $configPath,
        '--data-dir', $voicesRoot,
        '-f', $plan.OutputPath
    )

    if ($PSBoundParameters.ContainsKey('LengthScale')) {
        $piperArgs += @('--length-scale', $LengthScale.ToString([System.Globalization.CultureInfo]::InvariantCulture))
    }

    $piperArgs += @('--', $plan.Line)

    Write-Host ("Invoking Piper for line {0:D2}: {1}" -f $plan.Index, $plan.OutputPath) -ForegroundColor Cyan
    & $localPython @piperArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Piper exited with code $LASTEXITCODE for line $($plan.Index)."
    }

    if (-not (Test-Path -LiteralPath $plan.OutputPath -PathType Leaf)) {
        throw "Piper reported success but the expected WAV was not created: $($plan.OutputPath)"
    }

    $generatedFile = Get-Item -LiteralPath $plan.OutputPath
    Write-Host ("- output: {0}" -f $plan.OutputPath) -ForegroundColor Green
    Write-Host ("- size: {0} bytes" -f $generatedFile.Length)
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No autoplay"
Write-Host "- No microphone/audio capture"
Write-Host "- No app runtime TTS"
Write-Host "- No OpenClaw changes"
