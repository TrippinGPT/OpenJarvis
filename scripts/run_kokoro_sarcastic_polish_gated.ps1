[CmdletBinding()]
param(
    [switch]$AllowGenerate,
    [string[]]$Lines,
    [string]$Voice = 'af_bella',
    [string]$PythonExe = 'D:\AI\TRIPPIN_AI_RELAY\tools\kokoro.venv\Scripts\python.exe'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedRepoRoot = [System.IO.Path]::GetFullPath('D:\AI\TRIPPIN_AI_RELAY')
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repoRootPrefix = $repoRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$formatterScript = Join-Path $repoRoot 'scripts\format_smartmouth_lines.ps1'
$kokoroCachePath = Join-Path $repoRoot 'tools\kokoro\models'
$outputRoot = Join-Path $repoRoot 'outputs\tts_tests'
$relayVoiceProfilePath = Join-Path $repoRoot 'config\relay_voice_profiles.json'

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to run Kokoro outside the expected Relay repo: $expectedRepoRoot"
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

function Invoke-PythonProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Available = $false
            Success = $false
            Output = @('Not found')
        }
    }

    try {
        $output = @(& $Path @Arguments 2>&1)
        return [pscustomobject]@{
            Available = $true
            Success = ($LASTEXITCODE -eq 0)
            Output = $output
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $true
            Success = $false
            Output = @($_.Exception.Message)
        }
    }
}

function Get-KokoroPackageStatus {
    param([Parameter(Mandatory = $true)][string]$PythonPath)

    $versionProbe = Invoke-PythonProbe -Path $PythonPath -Arguments @('--version')
    $versionText = ($versionProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($versionText)) { $versionText = 'Not found' }

    $pipShowProbe = Invoke-PythonProbe -Path $PythonPath -Arguments @('-m', 'pip', 'show', 'kokoro')
    $pipShowText = ($pipShowProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
    $installed = $false
    if ($pipShowProbe.Available -and $pipShowProbe.Success -and $pipShowText -match '(?m)^Name:\s+kokoro\s*$') {
        $installed = $true
    }

    return [pscustomobject]@{
        Installed = $installed
        Version = $versionText
    }
}

function Get-SelectedLines {
    param([string[]]$RequestedLines)

    if ($RequestedLines -and $RequestedLines.Count -gt 0) {
        return @(
            $RequestedLines |
                ForEach-Object { "$_".Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
    }

    return @(
        'Routing now. We have a plan. Try not to ruin it.',
        "Routing now. Don't screw it up.",
        'We have a plan. Miracles happen.',
        'Relax. I already fixed it.'
    )
}

function Convert-SmartmouthEntryToText {
    param([Parameter(Mandatory = $true)]$Entry)

    $text = [string]$Entry.Text
    $pause = 'none'
    $emphasis = 'none'
    if ($Entry.PSObject.Properties.Name -contains 'PauseAfter') { $pause = [string]$Entry.PauseAfter }
    if ($Entry.PSObject.Properties.Name -contains 'Emphasis') { $emphasis = [string]$Entry.Emphasis }

    $rendered = $text.Trim().TrimEnd('.','!','?')
    switch ($pause) {
        'short' { $rendered = "$rendered." }
        'medium' { $rendered = "$rendered..." }
        'long' { $rendered = "$rendered... ..." }
        default {
            if ($rendered -notmatch '[.!?]$') { $rendered = "$rendered." }
        }
    }

    return [pscustomobject]@{
        Rendered = $rendered
        PauseAfter = $pause
        Emphasis = $emphasis
    }
}

function Apply-SmartmouthEmphasis {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [ValidateSet('none', 'slight', 'caps')][string]$Emphasis = 'none'
    )

    if ($Emphasis -eq 'none') { return $Text }

    $candidateMap = @('have', 'now', 'plan', 'ruin', 'stop', 'actually', 'screw', 'fixed', 'relax', 'miracles')
    foreach ($candidate in $candidateMap) {
        $pattern = "(?i)\b$([regex]::Escape($candidate))\b"
        if ($Text -match $pattern -and $Emphasis -eq 'caps') {
            return [regex]::Replace($Text, $pattern, { param($m) $m.Value.ToUpperInvariant() }, 1)
        }
    }

    return $Text
}

function Render-SpeechText {
    param([Parameter(Mandatory = $true)][object[]]$Entries)

    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $Entries) {
        $converted = Convert-SmartmouthEntryToText -Entry $entry
        $spoken = Apply-SmartmouthEmphasis -Text $converted.Rendered -Emphasis $converted.Emphasis
        [void]$parts.Add($spoken)
    }

    return ($parts -join ' ')
}

$selectedLines = Get-SelectedLines -RequestedLines $Lines
$kokoroPackageStatus = Get-KokoroPackageStatus -PythonPath $PythonExe
$kokoroVenvPresent = Test-Path -LiteralPath $PythonExe -PathType Leaf
$kokoroCachePresent = Test-Path -LiteralPath $kokoroCachePath -PathType Container
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host ''
Write-Host 'Relay Kokoro Sarcastic Polish' -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Voice: $Voice" -ForegroundColor Cyan
Write-Host "PythonExe: $PythonExe" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Selected lines' -ForegroundColor Cyan
for ($i = 0; $i -lt $selectedLines.Count; $i++) {
    Write-Host ("[{0}] {1}" -f ($i + 1), $selectedLines[$i])
}
Write-Host ''
Write-Host 'Kokoro runtime' -ForegroundColor Cyan
Write-Host "- python present: $kokoroVenvPresent"
Write-Host "- kokoro package: $(if ($kokoroPackageStatus.Installed) { "Installed ($($kokoroPackageStatus.Version))" } else { 'Missing' })"
Write-Host "- cache present: $kokoroCachePresent"
Write-Host ''

$plan = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $selectedLines.Count; $i++) {
    $lineNumber = $i + 1
    $lineText = $selectedLines[$i]
    $structured = @(& $formatterScript -Line $lineText -Mode sarcastic)
    $structured = @($structured | Where-Object { $_ -ne $null })
    $speechText = Render-SpeechText -Entries $structured
    $plannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot ("relay_sarcastic_polish_{0}_{1}.wav" -f ('{0:D2}' -f $lineNumber), $timestamp))
    [void]$plan.Add([pscustomobject]@{
        Index = $lineNumber
        Input = $lineText
        Structured = $structured
        SpeechText = $speechText
        Output = $plannedOutput
    })
}

Write-Host 'Planned polish lines' -ForegroundColor Cyan
foreach ($item in $plan) {
    Write-Host ("[{0}] input: {1}" -f ('{0:D2}' -f $item.Index), $item.Input)
    foreach ($entry in $item.Structured) {
        Write-Host ("    text: {0}" -f $entry.Text)
        Write-Host ("    pause: {0}" -f $entry.PauseAfter)
        Write-Host ("    emphasis: {0}" -f $entry.Emphasis)
    }
    Write-Host ("    speech: {0}" -f $item.SpeechText)
    Write-Host ("    output: {0}" -f $item.Output)
}
Write-Host ''

if (-not $AllowGenerate) {
    Write-Host 'Dry run complete. No audio was generated.' -ForegroundColor Yellow
    Write-Host 'No playback occurred.'
    Write-Host 'No microphone access occurred.'
    Write-Host 'No app runtime TTS was added.'
    Write-Host 'No OpenClaw changes were made.'
    return
}

if (-not $kokoroVenvPresent) { throw "Kokoro venv Python is missing: $PythonExe" }
if (-not $kokoroPackageStatus.Installed) { throw "Kokoro is not installed in the local venv: $PythonExe" }
if (-not $kokoroCachePresent) { throw "Kokoro cache is missing: $kokoroCachePath" }
if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) { New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null }

$tempInputPath = Join-Path $env:TEMP ("relay_sarcastic_polish_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
$tempPythonPath = Join-Path $env:TEMP ("relay_sarcastic_polish_{0}.py" -f ([guid]::NewGuid().ToString('N')))

try {
    $tempPythonScript = @'
import os
import sys
import wave
from pathlib import Path

import numpy as np
from kokoro import KPipeline

voice = sys.argv[1]
text = sys.argv[2]
output_path = Path(sys.argv[3])
cache_path = sys.argv[4]

os.environ["HF_HUB_CACHE"] = cache_path
os.environ["HUGGINGFACE_HUB_CACHE"] = cache_path
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"

pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M", device="cpu")
pipeline.load_voice(voice)

with wave.open(str(output_path.resolve()), "wb") as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(24000)

    for result in pipeline(text, voice=voice, speed=1.0, split_pattern=r"\n+"):
        if result.audio is None:
            continue
        wav_file.writeframes((np.clip(result.audio.numpy(), -1.0, 1.0) * 32767).astype(np.int16).tobytes())
'@
    [System.IO.File]::WriteAllText($tempPythonPath, $tempPythonScript, (New-Object System.Text.UTF8Encoding($false)))

    foreach ($item in $plan) {
        [System.IO.File]::WriteAllText($tempInputPath, $item.SpeechText + "`n", (New-Object System.Text.UTF8Encoding($false)))
        & $PythonExe $tempPythonPath $Voice $item.SpeechText $item.Output $kokoroCachePath
        if ($LASTEXITCODE -ne 0) {
            throw "Kokoro generation failed for line $($item.Index) with exit code $LASTEXITCODE."
        }
        if (-not (Test-Path -LiteralPath $item.Output -PathType Leaf)) {
            throw "Expected WAV was not created: $($item.Output)"
        }

        $fileInfo = Get-Item -LiteralPath $item.Output
        Write-Host ("Generated [{0}] {1}" -f ('{0:D2}' -f $item.Index), $item.Output)
        Write-Host ("- size: {0:N0} bytes" -f $fileInfo.Length)
    }

    Write-Host ''
    Write-Host 'Generation complete' -ForegroundColor Green
    Write-Host '- autoplay: disabled'
    Write-Host '- microphone: not used'
    Write-Host '- app runtime TTS: not added'
    Write-Host '- OpenClaw: untouched'
}
finally {
    Remove-Item -LiteralPath $tempInputPath, $tempPythonPath -Force -ErrorAction SilentlyContinue
}
