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
$configPath = Join-Path $repoRoot "config\piper_voice_models.json"
$localVenvPath = Join-Path $repoRoot "tools\piper.venv"
$localPython = Join-Path $localVenvPath "Scripts\python.exe"
$localPiperCommand = Join-Path $localVenvPath "Scripts\piper.exe"
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

function Write-SectionLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-34} {1}" -f "${Label}:", $Value)
}

if ($AllowGenerate) {
    Write-Error "Audio generation is reserved for v2.4 after voice model gate validation."
    exit 1
}

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Missing voice-model config: $configPath"
}

try {
    $voiceConfig = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
}
catch {
    throw "Voice-model config is invalid: $($_.Exception.Message)"
}

$selectedVoice = $voiceConfig.voices |
    Where-Object { $_.id -eq $voiceConfig.default_voice_id } |
    Select-Object -First 1

if ($null -eq $selectedVoice) {
    throw "Default voice id '$($voiceConfig.default_voice_id)' was not found in $configPath."
}

$modelPath = Assert-RelayPath -Path $selectedVoice.model_output_path
$configOutputPath = Assert-RelayPath -Path $selectedVoice.config_output_path
$voiceFolderExists = Test-Path -LiteralPath $voicesRoot -PathType Container
$modelExists = Test-Path -LiteralPath $modelPath -PathType Leaf
$configExists = Test-Path -LiteralPath $configOutputPath -PathType Leaf
$voiceModelCount = Get-Count -Folder $voicesRoot -Filter "*.onnx"
$voiceConfigCount = Get-Count -Folder $voicesRoot -Filter "*.onnx.json"
$localPiperInstalled = Test-PiperModule -PythonPath $localPython
$piperCommand = Get-Command "piper" -ErrorAction SilentlyContinue | Select-Object -First 1
$plannedLine = if (-not [string]::IsNullOrWhiteSpace($Line)) {
    $Line.Trim()
}
else {
    "Relay online. Ready for the next safe step."
}
$plannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot "relay-test-line-preview.wav")

Write-Host ""
Write-Host "Relay Piper Gated Test Line" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: DRY RUN" -ForegroundColor Cyan
Write-Host ""

Write-Host "Selected voice" -ForegroundColor Cyan
Write-SectionLine -Label "Voice id" -Value $selectedVoice.id
Write-SectionLine -Label "Display name" -Value $selectedVoice.display_name
Write-SectionLine -Label "Model output path" -Value $modelPath
Write-SectionLine -Label "Config output path" -Value $configOutputPath
Write-SectionLine -Label "Model present" -Value $modelExists.ToString()
Write-SectionLine -Label "Config present" -Value $configExists.ToString()
Write-SectionLine -Label "Voice folder" -Value $(if ($voiceFolderExists) { "Present" } else { "Missing, expected before model download." })
Write-SectionLine -Label ".onnx count" -Value $voiceModelCount.ToString()
Write-SectionLine -Label ".onnx.json count" -Value $voiceConfigCount.ToString()
Write-SectionLine -Label "Planned test line" -Value $plannedLine
Write-SectionLine -Label "Planned output path" -Value $plannedOutput
Write-SectionLine -Label "Local Piper module" -Value $(if ($localPiperInstalled) { "Installed in the Relay venv" } else { "Missing" })
Write-SectionLine -Label "Local Piper command" -Value $(if (Test-Path -LiteralPath $localPiperCommand -PathType Leaf) { $localPiperCommand } else { "Not found" })

Write-Host ""
if (-not $modelExists -or -not $configExists) {
    Write-Host "Model files are missing. This is expected before the approved voice-model download." -ForegroundColor Yellow
}
else {
    Write-Host "Model files are present. Generation would still remain gated until a later task." -ForegroundColor Green
}

Write-Host "Dry run complete. Audio generation is not available in v2.3." -ForegroundColor Yellow

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No model download attempted"
Write-Host "- No audio playback attempted"
Write-Host "- No microphone/audio capture used"
Write-Host "- No voice cloning or impersonation requested"
Write-Host "- OpenClaw was not touched"
