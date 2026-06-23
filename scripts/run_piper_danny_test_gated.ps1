[CmdletBinding()]
param(
    [switch]$AllowDownload,
    [switch]$AllowGenerate,
    [string]$Line,
    [double[]]$LengthScales
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
$piperExe = Join-Path $repoRoot "tools\piper.venv\Scripts\piper.exe"

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

function Format-FileSize {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path
    return ("{0:N0} bytes" -f $item.Length)
}

function Get-LengthScales {
    param(
        [double[]]$RequestedLengthScales
    )

    if ($RequestedLengthScales -and $RequestedLengthScales.Count -gt 0) {
        return @(
            $RequestedLengthScales |
                ForEach-Object { [double]$_ }
        )
    }

    return @(1.0, 0.9, 0.85)
}

$voiceConfig = Get-VoiceConfig
$dannyVoice = Get-VoiceById -Config $voiceConfig -RequestedVoiceId "en_US_danny_low"
$modelPath = Assert-RelayPath -Path $dannyVoice.model_output_path
$configPath = Assert-RelayPath -Path $dannyVoice.config_output_path
$modelExists = Test-Path -LiteralPath $modelPath -PathType Leaf
$configExists = Test-Path -LiteralPath $configPath -PathType Leaf
$localPythonExists = Test-Path -LiteralPath $localPython -PathType Leaf
$piperExeExists = Test-Path -LiteralPath $piperExe -PathType Leaf
$selectedLine = if (-not [string]::IsNullOrWhiteSpace($Line)) {
    $Line.Trim()
}
else {
    "Routing that now. Shocking development: we are using a plan."
}
$lengthScales = Get-LengthScales -RequestedLengthScales $LengthScales
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$plannedOutputs = @()
foreach ($scale in $lengthScales) {
    if ($scale -le 0) {
        throw "Length scale must be positive: $scale"
    }

    $scaleToken = [int][Math]::Round($scale * 100, 0)
    $plannedOutputs += [pscustomobject]@{
        Scale = [double]$scale
        ScaleToken = ("{0:D3}" -f $scaleToken)
        OutputPath = Assert-RelayPath -Path (Join-Path $outputRoot ("relay_danny_test_ls{0:D3}_{1}.wav" -f $scaleToken, $timestamp))
    }
}

Write-Host ""
Write-Host "Relay Piper Danny Test" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowDownload -or $AllowGenerate) { 'APPROVAL GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Selected voice" -ForegroundColor Cyan
Write-Host "- id: $($dannyVoice.id)"
Write-Host "- display name: $($dannyVoice.display_name)"
Write-Host "- language: $($dannyVoice.language)"
Write-Host "- quality: $($dannyVoice.quality)"
Write-Host "- status: $($dannyVoice.status)"
Write-Host "- review status: $($dannyVoice.review_status)"
Write-Host "- relay fit: $($dannyVoice.relay_fit)"
Write-Host "- technical status: $($dannyVoice.technical_status)"
Write-Host "- source: $($dannyVoice.source_note)"
Write-Host "- usage boundary: $($dannyVoice.usage_boundary)"
Write-Host "- model output path: $modelPath"
Write-Host "- config output path: $configPath"
Write-Host "- model present: $modelExists"
Write-Host "- config present: $configExists"
Write-Host "- local Piper Python: $(if ($localPythonExists) { $localPython } else { 'Missing' })"
Write-Host "- local Piper executable: $(if ($piperExeExists) { $piperExe } else { 'Missing' })"
Write-Host ""

Write-Host "Planned line" -ForegroundColor Cyan
Write-Host $selectedLine
Write-Host ""
Write-Host "Planned length scales" -ForegroundColor Cyan
foreach ($scale in $lengthScales) {
    Write-Host ("- {0}" -f $scale.ToString([System.Globalization.CultureInfo]::InvariantCulture))
}
Write-Host ""
Write-Host "Planned output folder: $outputRoot" -ForegroundColor Cyan
foreach ($plan in $plannedOutputs) {
    Write-Host ("- planned output: {0}" -f $plan.OutputPath)
}
Write-Host ""
Write-Host "Download requires -AllowDownload." -ForegroundColor Yellow
Write-Host "Generation requires -AllowGenerate." -ForegroundColor Yellow
Write-Host "No autoplay will occur." -ForegroundColor Yellow
Write-Host "No microphone/audio capture will occur." -ForegroundColor Yellow
Write-Host "No runtime TTS will be added." -ForegroundColor Yellow
Write-Host "No OpenClaw changes will be made." -ForegroundColor Yellow

if (-not $AllowDownload -and -not $AllowGenerate) {
    Write-Host ""
    Write-Host "Dry run complete. No audio was generated." -ForegroundColor Yellow
    return
}

if ($AllowDownload) {
    if (-not (Test-Path -LiteralPath $voicesRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $voicesRoot | Out-Null
    }

    Invoke-DownloadIfMissing -Uri $dannyVoice.model_url -TargetPath $modelPath -Label "Danny model"
    Invoke-DownloadIfMissing -Uri $dannyVoice.config_url -TargetPath $configPath -Label "Danny config"

    if (-not (Test-Path -LiteralPath $modelPath -PathType Leaf)) {
        throw "Danny model download did not create the expected file: $modelPath"
    }
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Danny config download did not create the expected file: $configPath"
    }

    Write-Host ""
    Write-Host "Download result" -ForegroundColor Green
    Write-Host "- model size: $(Format-FileSize -Path $modelPath)"
    Write-Host "- config size: $(Format-FileSize -Path $configPath)"
}

if ($AllowGenerate) {
    $modelExists = Test-Path -LiteralPath $modelPath -PathType Leaf
    $configExists = Test-Path -LiteralPath $configPath -PathType Leaf

    if (-not $modelExists -or -not $configExists) {
        throw "Danny voice model files are missing. Run with -AllowDownload first or together with -AllowGenerate."
    }

    if (-not $piperExeExists) {
        throw "Piper is not available in the local Relay venv: $piperExe"
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
            '-m', $modelPath,
            '-c', $configPath,
            '-f', $plan.OutputPath,
            '--length-scale', $plan.Scale.ToString([System.Globalization.CultureInfo]::InvariantCulture),
            '--',
            $selectedLine
        )

        Write-Host ("Invoking Piper for length scale {0}: {1}" -f $plan.Scale, $plan.OutputPath) -ForegroundColor Cyan
        & $piperExe @piperArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Piper exited with code $LASTEXITCODE for length scale $($plan.Scale)."
        }

        if (-not (Test-Path -LiteralPath $plan.OutputPath -PathType Leaf)) {
            throw "Piper reported success but the expected WAV was not created: $($plan.OutputPath)"
        }

        $generatedFile = Get-Item -LiteralPath $plan.OutputPath
        Write-Host ("- output: {0}" -f $plan.OutputPath) -ForegroundColor Green
        Write-Host ("- size: {0} bytes" -f $generatedFile.Length)
    }
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No autoplay"
Write-Host "- No microphone/audio capture"
Write-Host "- No app runtime TTS"
Write-Host "- No OpenClaw changes"
