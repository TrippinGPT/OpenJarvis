[CmdletBinding()]
param(
    [switch]$AllowGenerate,
    [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
    [string]$Mode = 'neutral',
    [string]$Line
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedRepoRoot = [System.IO.Path]::GetFullPath('D:\AI\TRIPPIN_AI_RELAY')
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repoRootPrefix = $repoRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$kokoroPython = Join-Path $repoRoot 'tools\kokoro.venv\Scripts\python.exe'
$kokoroCachePath = Join-Path $repoRoot 'tools\kokoro\models'
$outputRoot = Join-Path $repoRoot 'outputs\tts_tests'
$formatterScript = Join-Path $repoRoot 'scripts\format_smartmouth_lines.ps1'
$relayVoiceProfilePath = Join-Path $repoRoot 'config\relay_voice_profiles.json'
$voiceId = 'af_bella'

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
        [string]$PythonPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
        return [pscustomobject]@{
            Available = $false
            Success = $false
            Output = @('Not found')
        }
    }

    try {
        $output = @(& $PythonPath @Arguments 2>&1)
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
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath
    )

    $versionProbe = Invoke-PythonProbe -PythonPath $PythonPath -Arguments @('--version')
    $versionText = ($versionProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($versionText)) {
        $versionText = 'Not found'
    }

    $pipShowProbe = Invoke-PythonProbe -PythonPath $PythonPath -Arguments @('-m', 'pip', 'show', 'kokoro')
    $pipShowText = ($pipShowProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
    $kokoroInstalled = $false
    if ($pipShowProbe.Available -and $pipShowProbe.Success -and $pipShowText -match '(?m)^Name:\s+kokoro\s*$') {
        $kokoroInstalled = $true
    }

    $importProbe = Invoke-PythonProbe -PythonPath $PythonPath -Arguments @('-c', 'import kokoro; print(kokoro.__file__)')
    $importText = ($importProbe.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($importText)) {
        $importText = 'Not found'
    }

    return [pscustomobject]@{
        Installed = $kokoroInstalled
        Version = if ($versionText) { $versionText } else { 'Not found' }
        ImportPath = $importText
    }
}

function Get-SelectedLine {
    param([string]$RequestedLine)

    if (-not [string]::IsNullOrWhiteSpace($RequestedLine)) {
        return [pscustomobject]@{
            Line = $RequestedLine.Trim()
            Source = 'command line'
        }
    }

    if (-not (Test-Path -LiteralPath $relayVoiceProfilePath -PathType Leaf)) {
        return [pscustomobject]@{
            Line = 'Relay online. Try not to break anything expensive.'
            Source = 'fallback'
        }
    }

    try {
        $relayProfiles = Get-Content -LiteralPath $relayVoiceProfilePath -Raw | ConvertFrom-Json
        $defaultProfileId = $null
        if ($relayProfiles.PSObject.Properties.Name -contains 'default_voice') {
            $defaultProfileId = [string]$relayProfiles.default_voice
        }
        elseif ($relayProfiles.PSObject.Properties.Name -contains 'default_voice_id') {
            $defaultProfileId = [string]$relayProfiles.default_voice_id
        }

        if ([string]::IsNullOrWhiteSpace($defaultProfileId)) {
            $defaultProfileId = 'smartmouth_relay'
        }

        $profile = $relayProfiles.voices |
            Where-Object { $_.id -eq $defaultProfileId } |
            Select-Object -First 1
        if ($null -eq $profile) {
            $profile = $relayProfiles.voices |
                Where-Object { $_.id -eq 'smartmouth_relay' } |
                Select-Object -First 1
        }

        if ($null -ne $profile -and @($profile.do_say).Count -gt 0) {
            return [pscustomobject]@{
                Line = [string]$profile.do_say[0]
                Source = "config\relay_voice_profiles.json:$($profile.id)"
            }
        }
    }
    catch {
    }

    return [pscustomobject]@{
        Line = 'Relay online. Try not to break anything expensive.'
        Source = 'fallback'
    }
}

function Test-GitIgnoredPattern {
    param([Parameter(Mandatory = $true)][string]$Path)

    & git -C $repoRoot check-ignore -q -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Convert-SmartmouthEntryToText {
    param(
        [Parameter(Mandatory = $true)]
        $Entry
    )

    $text = [string]$Entry.Text
    $pause = 'none'
    $emphasis = 'none'

    if ($Entry.PSObject.Properties.Name -contains 'PauseAfter') {
        $pause = [string]$Entry.PauseAfter
    }
    if ($Entry.PSObject.Properties.Name -contains 'Emphasis') {
        $emphasis = [string]$Entry.Emphasis
    }

    $spokenText = $text.Trim().TrimEnd('.','!','?')
    if ([string]::IsNullOrWhiteSpace($spokenText)) {
        return [pscustomobject]@{
            Rendered = $null
            PauseAfter = $pause
            Emphasis = $emphasis
        }
    }

    switch ($pause) {
        'short' { $spokenText = "$spokenText." }
        'medium' { $spokenText = "$spokenText..." }
        'long' { $spokenText = "$spokenText... ..." }
        default {
            if ($spokenText -notmatch '[.!?]$') {
                $spokenText = "$spokenText."
            }
        }
    }

    return [pscustomobject]@{
        Rendered = $spokenText
        PauseAfter = $pause
        Emphasis = $emphasis
    }
}

function Apply-SmartmouthEmphasis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
        [string]$Mode,

        [ValidateSet('none', 'slight', 'caps')]
        [string]$Emphasis = 'none'
    )

    if ($Mode -notin @('sarcastic', 'command') -or $Emphasis -eq 'none') {
        return $Text
    }

    $candidateMap = switch ($Mode) {
        'sarcastic' { @('have', 'now', 'plan', 'ruin', 'stop', 'actually') }
        'command' { @('stay', 'stop', 'now', 'task', 'route', 'move', 'go') }
        default { @() }
    }

    foreach ($candidate in $candidateMap) {
        $pattern = "(?i)\b$([regex]::Escape($candidate))\b"
        if ($Text -match $pattern) {
            if ($Emphasis -eq 'caps') {
                return [regex]::Replace($Text, $pattern, { param($m) $m.Value.ToUpperInvariant() }, 1)
            }

            if ($Emphasis -eq 'slight') {
                return [regex]::Replace($Text, $pattern, { param($m) $m.Value.Substring(0,1).ToUpperInvariant() + $m.Value.Substring(1).ToLowerInvariant() }, 1)
            }
        }
    }

    return $Text
}

function Render-SmartmouthSpeechText {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Entries,

        [Parameter(Mandatory = $true)]
        [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
        [string]$Mode
    )

    $rendered = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $Entries) {
        $converted = Convert-SmartmouthEntryToText -Entry $entry
        if ([string]::IsNullOrWhiteSpace($converted.Rendered)) {
            continue
        }

        $spoken = Apply-SmartmouthEmphasis -Text $converted.Rendered -Mode $Mode -Emphasis $converted.Emphasis
        [void]$rendered.Add($spoken)
    }

    return ($rendered -join ' ')
}

$selectedLine = Get-SelectedLine -RequestedLine $Line
$formatterResult = @(& $formatterScript -Line $selectedLine.Line -Mode $Mode)
$formatterResult = @(
    $formatterResult |
        Where-Object { $_ -ne $null }
)

if ($formatterResult.Count -eq 0) {
    throw 'Smartmouth formatter produced no lines.'
}

$finalSpeechText = Render-SmartmouthSpeechText -Entries $formatterResult -Mode $Mode
if ([string]::IsNullOrWhiteSpace($finalSpeechText)) {
    throw 'Smartmouth renderer produced no speech text.'
}

$kokoroPackageStatus = Get-KokoroPackageStatus -PythonPath $kokoroPython
$kokoroVenvPresent = Test-Path -LiteralPath $kokoroPython -PathType Leaf
$kokoroCachePresent = Test-Path -LiteralPath $kokoroCachePath -PathType Container
$kokoroCacheFileCount = if ($kokoroCachePresent) {
    @(
        Get-ChildItem -LiteralPath $kokoroCachePath -Recurse -File -ErrorAction SilentlyContinue
    ).Count
} else {
    0
}
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$plannedOutput = Assert-RelayPath -Path (Join-Path $outputRoot "relay_smartmouth_$timestamp.wav")
$ignoreChecks = [ordered]@{
    'tools/kokoro.venv/' = (Test-GitIgnoredPattern -Path 'tools/kokoro.venv/')
    'tools/kokoro/models/' = (Test-GitIgnoredPattern -Path 'tools/kokoro/models/')
    'outputs/tts_tests/*.wav' = (Test-GitIgnoredPattern -Path 'outputs/tts_tests/placeholder.wav')
    'outputs/tts_tests/*.mp3' = (Test-GitIgnoredPattern -Path 'outputs/tts_tests/placeholder.mp3')
}

Write-Host ''
Write-Host 'Relay Smartmouth Kokoro Test' -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f $(if ($AllowGenerate) { 'generation requested' } else { 'dry run' })) -ForegroundColor Cyan
Write-Host "Voice: $voiceId" -ForegroundColor Cyan
Write-Host ''

Write-Host 'Selected line' -ForegroundColor Cyan
Write-Host "- source: $($selectedLine.Source)"
Write-Host "- input: $($selectedLine.Line)"
Write-Host ''

Write-Host 'Smartmouth structured lines' -ForegroundColor Cyan
$lineIndex = 0
foreach ($entry in $formatterResult) {
    $lineIndex++
    Write-Host ("[{0}] text: {1}" -f $lineIndex, $entry.Text)
    Write-Host ("    pause: {0}" -f $entry.PauseAfter)
    Write-Host ("    emphasis: {0}" -f $entry.Emphasis)
}
Write-Host ''
Write-Host 'Rendered speech text' -ForegroundColor Cyan
Write-Host $finalSpeechText
Write-Host "- planned output: $plannedOutput"
Write-Host ''

Write-Host 'Kokoro runtime' -ForegroundColor Cyan
Write-Host "- venv python present: $kokoroVenvPresent"
Write-Host "- kokoro package: $(if ($kokoroPackageStatus.Installed) { "Installed ($($kokoroPackageStatus.Version))" } else { "Missing" })"
Write-Host "- kokoro import path: $($kokoroPackageStatus.ImportPath)"
Write-Host "- cache present: $kokoroCachePresent"
Write-Host "- cache file count: $kokoroCacheFileCount"
Write-Host ''

Write-Host 'Ignore checks' -ForegroundColor Cyan
foreach ($item in $ignoreChecks.GetEnumerator()) {
    Write-Host ("- {0}: {1}" -f $item.Key, $(if ($item.Value) { 'ignored' } else { 'not ignored' }))
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

if (-not $kokoroVenvPresent) {
    throw "Kokoro venv Python is missing: $kokoroPython"
}

if (-not $kokoroPackageStatus.Installed) {
    throw "Kokoro is not installed in the local venv: $kokoroPython"
}

if (-not $kokoroCachePresent) {
    throw "Kokoro cache is missing: $kokoroCachePath"
}

if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
}

if (Test-Path -LiteralPath $plannedOutput -PathType Leaf) {
    throw "Planned output already exists: $plannedOutput"
}

$tempInputPath = Join-Path $env:TEMP ("relay_smartmouth_input_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
$tempPythonPath = Join-Path $env:TEMP ("relay_smartmouth_kokoro_{0}.py" -f ([guid]::NewGuid().ToString('N')))

try {
    [System.IO.File]::WriteAllText($tempInputPath, $finalSpeechText + "`n", (New-Object System.Text.UTF8Encoding($false)))
    $tempPythonScript = @'
import os
import sys
import wave
from pathlib import Path

import numpy as np
from kokoro import KPipeline

voice = sys.argv[1]
input_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])
cache_path = sys.argv[4]

os.environ["HF_HUB_CACHE"] = cache_path
os.environ["HUGGINGFACE_HUB_CACHE"] = cache_path
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"

text = input_path.read_text(encoding="utf-8").strip()
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

    & $kokoroPython $tempPythonPath $voiceId $tempInputPath $plannedOutput $kokoroCachePath
    if ($LASTEXITCODE -ne 0) {
        throw "Kokoro generation failed with exit code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $plannedOutput -PathType Leaf)) {
        throw "Expected WAV was not created: $plannedOutput"
    }

    $item = Get-Item -LiteralPath $plannedOutput
    Write-Host ''
    Write-Host 'Generation complete' -ForegroundColor Green
    Write-Host "- output: $plannedOutput"
    Write-Host ("- size: {0:N0} bytes" -f $item.Length)
    Write-Host '- autoplay: disabled'
    Write-Host '- microphone: not used'
    Write-Host '- app runtime TTS: not added'
    Write-Host '- OpenClaw: untouched'
}
finally {
    Remove-Item -LiteralPath $tempInputPath, $tempPythonPath -Force -ErrorAction SilentlyContinue
}
