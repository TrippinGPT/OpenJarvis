[CmdletBinding()]
param(
    [switch]$AllowDownload,
    [string]$VoiceId = "en_US_lessac_medium"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedRepoRoot = [System.IO.Path]::GetFullPath("D:\AI\TRIPPIN_AI_RELAY")
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$repoRootPrefix = $repoRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$configPath = Join-Path $repoRoot "config\piper_voice_models.json"

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to download Piper voice models outside the expected Relay repo: $expectedRepoRoot"
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

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Missing voice-model config: $configPath"
}

try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
}
catch {
    throw "Voice-model config is invalid: $($_.Exception.Message)"
}

$selectedVoice = $config.voices |
    Where-Object { $_.id -eq $VoiceId } |
    Select-Object -First 1

if ($null -eq $selectedVoice) {
    throw "VoiceId '$VoiceId' was not found in $configPath."
}

$modelPath = Assert-RelayPath -Path $selectedVoice.model_output_path
$configOutputPath = Assert-RelayPath -Path $selectedVoice.config_output_path
$voicesRoot = Split-Path -Parent $modelPath
$voiceFolderExists = Test-Path -LiteralPath $voicesRoot -PathType Container
$modelExists = Test-Path -LiteralPath $modelPath -PathType Leaf
$configExists = Test-Path -LiteralPath $configOutputPath -PathType Leaf
$onnxCount = Get-Count -Folder $voicesRoot -Filter "*.onnx"
$onnxJsonCount = Get-Count -Folder $voicesRoot -Filter "*.onnx.json"

Write-Host ""
Write-Host "Relay Piper Voice Model Gate" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowDownload) { 'DOWNLOAD GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Selected voice" -ForegroundColor Cyan
Write-Host "- id: $($selectedVoice.id)"
Write-Host "- display name: $($selectedVoice.display_name)"
Write-Host "- language: $($selectedVoice.language)"
Write-Host "- quality: $($selectedVoice.quality)"
Write-Host "- status: $($selectedVoice.status)"
Write-Host "- license review: $($selectedVoice.license_review_status)"
Write-Host "- source: $($selectedVoice.source_note)"
Write-Host "- usage boundary: $($selectedVoice.usage_boundary)"
Write-Host "- model filename: $($selectedVoice.model_filename)"
Write-Host "- config filename: $($selectedVoice.config_filename)"
Write-Host "- model output path: $modelPath"
Write-Host "- config output path: $configOutputPath"
Write-Host "- model URL: $($selectedVoice.model_url)"
Write-Host "- config URL: $($selectedVoice.config_url)"
Write-Host ""

Write-Host "Voice folder" -ForegroundColor Cyan
Write-Host "- exists: $voiceFolderExists"
Write-Host "- .onnx count: $onnxCount"
Write-Host "- .onnx.json count: $onnxJsonCount"
Write-Host "- selected model present: $modelExists"
Write-Host "- selected config present: $configExists"
Write-Host ""

Write-Host "License and model-card reminder" -ForegroundColor Yellow
Write-Host "- Review the model card and license before any redistribution." -ForegroundColor Yellow
Write-Host "- Keep voice files local and untracked by Git." -ForegroundColor Yellow
Write-Host ""

if (-not $AllowDownload) {
    Write-Host "Dry run complete. Download requires -AllowDownload." -ForegroundColor Yellow
    Write-Host "No model was downloaded." -ForegroundColor Yellow
    Write-Host "No audio was generated." -ForegroundColor Yellow
    Write-Host "No microphone/audio capture was used." -ForegroundColor Yellow
    Write-Host "No OpenClaw changes were made." -ForegroundColor Yellow
    return
}

if (-not $voiceFolderExists) {
    New-Item -ItemType Directory -Path $voicesRoot | Out-Null
}

Invoke-DownloadIfMissing -Uri $selectedVoice.model_url -TargetPath $modelPath -Label "voice model"
Invoke-DownloadIfMissing -Uri $selectedVoice.config_url -TargetPath $configOutputPath -Label "voice config"

if (-not (Test-Path -LiteralPath $modelPath -PathType Leaf)) {
    throw "Voice model download did not create the expected file: $modelPath"
}
if (-not (Test-Path -LiteralPath $configOutputPath -PathType Leaf)) {
    throw "Voice config download did not create the expected file: $configOutputPath"
}

$onnxCount = Get-Count -Folder $voicesRoot -Filter "*.onnx"
$onnxJsonCount = Get-Count -Folder $voicesRoot -Filter "*.onnx.json"

Write-Host ""
Write-Host "Download result" -ForegroundColor Green
Write-Host "- Model file: $modelPath"
Write-Host "- Model size: $(Format-FileSize -Path $modelPath)"
Write-Host "- Config file: $configOutputPath"
Write-Host "- Config size: $(Format-FileSize -Path $configOutputPath)"
Write-Host "- Voice folder: $voicesRoot"
Write-Host "- .onnx count: $onnxCount"
Write-Host "- .onnx.json count: $onnxJsonCount"

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No audio was generated"
Write-Host "- No autoplay occurred"
Write-Host "- No microphone/audio capture was used"
Write-Host "- No OpenClaw changes were made"
Write-Host "- Files were limited to the selected voice model pair"
