[CmdletBinding()]
param(
    [switch]$AllowDownload,
    [switch]$AllowGenerate,
    [string[]]$VoiceIds,
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

function Get-ComparisonVoiceIds {
    param(
        [Parameter(Mandatory = $true)]
        $Config,

        [string[]]$RequestedVoiceIds
    )

    if ($RequestedVoiceIds -and $RequestedVoiceIds.Count -gt 0) {
        return @(
            $RequestedVoiceIds |
                ForEach-Object { "$_".Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
    }

    return @(
        "en_US_lessac_medium",
        "en_US_amy_medium",
        "en_US_ljspeech_medium"
    )
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

function Invoke-DownloadIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
        Write-Host "$Label already present: $TargetPath" -ForegroundColor Green
        return
    }

    $tempPath = "$TargetPath.download"
    if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
        Remove-Item -LiteralPath $tempPath -Force
    }

    Write-Host "Downloading $Label..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Uri -OutFile $tempPath -TimeoutSec 600
    Move-Item -LiteralPath $tempPath -Destination $TargetPath -Force
    Write-Host ("Downloaded {0}: {1}" -f $Label, $TargetPath) -ForegroundColor Green
}

$voiceConfig = Get-VoiceConfig
$comparisonVoiceIds = Get-ComparisonVoiceIds -Config $voiceConfig -RequestedVoiceIds $VoiceIds
if ($comparisonVoiceIds.Count -eq 0) {
    throw "No comparison voices were selected."
}

$selectedVoices = foreach ($voiceId in $comparisonVoiceIds) {
    Get-VoiceById -Config $voiceConfig -RequestedVoiceId $voiceId
}

$selectedLine = if (-not [string]::IsNullOrWhiteSpace($Line)) {
    $Line.Trim()
}
else {
    "Relay online. Try not to break anything expensive."
}

$voiceFolderExists = Test-Path -LiteralPath $voicesRoot -PathType Container
$localPythonExists = Test-Path -LiteralPath $localPython -PathType Leaf
$comparisonCandidateCount = @(
    $voiceConfig.voices |
        Where-Object {
            ($_.PSObject.Properties.Name -contains "comparison_candidate" -and $_.comparison_candidate -eq $true) -or
            $_.status -eq "candidate_for_local_comparison"
        }
).Count
$downloadedVoicePairCount = 0
foreach ($voice in @($voiceConfig.voices | Where-Object {
    ($_.PSObject.Properties.Name -contains "comparison_candidate" -and $_.comparison_candidate -eq $true) -or
    $_.status -eq "candidate_for_local_comparison"
})) {
    $modelPath = Assert-RelayPath -Path $voice.model_output_path
    $configOutputPath = Assert-RelayPath -Path $voice.config_output_path
    if ((Test-Path -LiteralPath $modelPath -PathType Leaf) -and (Test-Path -LiteralPath $configOutputPath -PathType Leaf)) {
        $downloadedVoicePairCount++
    }
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$plannedOutputs = @()
foreach ($voice in $selectedVoices) {
    $plannedOutputs += [pscustomobject]@{
        Voice = $voice
        ModelPath = Assert-RelayPath -Path $voice.model_output_path
        ConfigPath = Assert-RelayPath -Path $voice.config_output_path
        PlannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot ("relay_compare_{0}_{1}.wav" -f $voice.id, $timestamp))
    }
}

$existingComparisonWavs = @()
if (Test-Path -LiteralPath $outputRoot -PathType Container) {
    $existingComparisonWavs = @(
        Get-ChildItem -LiteralPath $outputRoot -Recurse -File -Filter "relay_compare_*.wav" |
            Sort-Object LastWriteTime, FullName
    )
}
$comparisonWavCount = $existingComparisonWavs.Count
$latestComparisonWav = $null
if ($comparisonWavCount -gt 0) {
    $latestComparisonWav = $existingComparisonWavs |
        Sort-Object -Property @{ Expression = "LastWriteTime"; Descending = $true }, "FullName" |
        Select-Object -First 1
}

Write-Host ""
Write-Host "Relay Piper Voice Comparison" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowDownload -or $AllowGenerate) { 'APPROVAL GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Comparison voices" -ForegroundColor Cyan
Write-Host "- requested count: $($selectedVoices.Count)"
Write-Host "- comparison candidate count in config: $comparisonCandidateCount"
Write-Host "- downloaded comparison voice pairs: $downloadedVoicePairCount"
Write-Host "- default line: $selectedLine"
Write-Host "- voices root: $voicesRoot"
Write-Host "- output root: $outputRoot"
Write-Host "- local Piper Python: $(if ($localPythonExists) { $localPython } else { 'Missing' })"
Write-Host "- voice folder present: $voiceFolderExists"
Write-Host ""

foreach ($plan in $plannedOutputs) {
    $modelExists = Test-Path -LiteralPath $plan.ModelPath -PathType Leaf
    $configExists = Test-Path -LiteralPath $plan.ConfigPath -PathType Leaf
    Write-Host "Voice: $($plan.Voice.id)" -ForegroundColor Cyan
    Write-Host "- display name: $($plan.Voice.display_name)"
    Write-Host "- status: $($plan.Voice.status)"
    Write-Host "- comparison candidate: $(if ($plan.Voice.PSObject.Properties.Name -contains 'comparison_candidate') { [string]$plan.Voice.comparison_candidate } else { 'false' })"
    Write-Host "- model output path: $($plan.ModelPath)"
    Write-Host "- config output path: $($plan.ConfigPath)"
    Write-Host "- model present: $modelExists"
    Write-Host "- config present: $configExists"
    Write-Host "- download needed: $(if ($modelExists -and $configExists) { 'No' } else { 'Yes' })"
    Write-Host "- planned output WAV: $($plan.PlannedOutput)"
    Write-Host ""
}

Write-Host "Dry-run and gate reminders" -ForegroundColor Yellow
Write-Host "- Download requires -AllowDownload."
Write-Host "- Generation requires -AllowGenerate."
Write-Host "- No autoplay will occur."
Write-Host "- No microphone/audio capture will occur."
Write-Host "- No runtime TTS will be added."
Write-Host "- No OpenClaw changes will be made."

if (-not $AllowDownload -and -not $AllowGenerate) {
    Write-Host ""
    Write-Host "Dry run complete. No files were created or modified." -ForegroundColor Yellow
    return
}

if ($AllowDownload) {
    if (-not $voiceFolderExists) {
        New-Item -ItemType Directory -Path $voicesRoot | Out-Null
        $voiceFolderExists = $true
    }

    Write-Host ""
    Write-Host "Download phase" -ForegroundColor Cyan
    foreach ($plan in $plannedOutputs) {
        Invoke-DownloadIfMissing -Uri $plan.Voice.model_url -TargetPath $plan.ModelPath -Label "$($plan.Voice.id) model"
        Invoke-DownloadIfMissing -Uri $plan.Voice.config_url -TargetPath $plan.ConfigPath -Label "$($plan.Voice.id) config"

        if (-not (Test-Path -LiteralPath $plan.ModelPath -PathType Leaf)) {
            throw "Voice model download did not create the expected file: $($plan.ModelPath)"
        }
        if (-not (Test-Path -LiteralPath $plan.ConfigPath -PathType Leaf)) {
            throw "Voice config download did not create the expected file: $($plan.ConfigPath)"
        }

        Write-Host ("- {0} model size: {1}" -f $plan.Voice.id, (Format-FileSize -Path $plan.ModelPath))
        Write-Host ("- {0} config size: {1}" -f $plan.Voice.id, (Format-FileSize -Path $plan.ConfigPath))
    }
}

if ($AllowGenerate) {
    if (-not $localPythonExists) {
        throw "Piper Python is not available in the local Relay venv: $localPython"
    }

    foreach ($plan in $plannedOutputs) {
        if (-not (Test-Path -LiteralPath $plan.ModelPath -PathType Leaf) -or -not (Test-Path -LiteralPath $plan.ConfigPath -PathType Leaf)) {
            throw "Selected voice pair is missing: $($plan.Voice.id). Run with -AllowDownload first or together with -AllowGenerate."
        }
    }

    if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $outputRoot | Out-Null
    }

    Write-Host ""
    Write-Host "Generation phase" -ForegroundColor Cyan
    foreach ($plan in $plannedOutputs) {
        if (Test-Path -LiteralPath $plan.PlannedOutput -PathType Leaf) {
            throw "Planned output already exists: $($plan.PlannedOutput)"
        }

        $modelName = [System.IO.Path]::GetFileNameWithoutExtension($plan.Voice.model_filename)
        $piperArgs = @(
            '-m', 'piper',
            '-m', $modelName,
            '--data-dir', $voicesRoot,
            '-f', $plan.PlannedOutput,
            '--',
            $selectedLine
        )

        Write-Host ("Invoking Piper for {0}: {1}" -f $plan.Voice.id, $plan.PlannedOutput) -ForegroundColor Cyan
        & $localPython @piperArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Piper exited with code $LASTEXITCODE for voice $($plan.Voice.id)."
        }

        if (-not (Test-Path -LiteralPath $plan.PlannedOutput -PathType Leaf)) {
            throw "Piper reported success but the expected WAV was not created: $($plan.PlannedOutput)"
        }

        $generatedFile = Get-Item -LiteralPath $plan.PlannedOutput
        Write-Host ("- {0} WAV: {1}" -f $plan.Voice.id, $plan.PlannedOutput) -ForegroundColor Green
        Write-Host ("- {0} size: {1} bytes" -f $plan.Voice.id, $generatedFile.Length)
    }
}

$comparisonWavs = @()
if (Test-Path -LiteralPath $outputRoot -PathType Container) {
    $comparisonWavs = @(
        Get-ChildItem -LiteralPath $outputRoot -Recurse -File -Filter "relay_compare_*.wav" |
            Sort-Object LastWriteTime, FullName
    )
}
$comparisonWavCount = $comparisonWavs.Count
$latestComparisonWav = $null
if ($comparisonWavCount -gt 0) {
    $latestComparisonWav = $comparisonWavs |
        Sort-Object -Property @{ Expression = "LastWriteTime"; Descending = $true }, "FullName" |
        Select-Object -First 1
}

Write-Host ""
Write-Host "Comparison result" -ForegroundColor Green
Write-Host "- comparison WAV count: $comparisonWavCount"
Write-Host "- latest comparison WAV: $(if ($null -ne $latestComparisonWav) { $latestComparisonWav.FullName } else { 'None' })"
Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No autoplay"
Write-Host "- No microphone/audio capture"
Write-Host "- No app runtime TTS"
Write-Host "- No OpenClaw changes"
