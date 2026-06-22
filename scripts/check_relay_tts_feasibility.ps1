[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$voiceConfigPath = Join-Path $repoRoot "config\relay_voice_profiles.json"
$ttsPlanPath = Join-Path $repoRoot "docs\RELAY_TTS_PLAN.md"

function Get-CommandDetails {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string[]]$VersionArguments = @("--version")
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{
            Available = $false
            Version = "Not found"
        }
    }

    try {
        $versionOutput = & $command.Source @VersionArguments 2>&1
        $versionText = ($versionOutput | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join " "

        if ([string]::IsNullOrWhiteSpace($versionText)) {
            $versionText = "Available (version not reported)"
        }

        return [pscustomobject]@{
            Available = $true
            Version = $versionText
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $true
            Version = "Available (version check failed: $($_.Exception.Message))"
        }
    }
}

function Write-CheckLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-28} {1}" -f "${Label}:", $Value)
}

$configExists = Test-Path -LiteralPath $voiceConfigPath -PathType Leaf
$planExists = Test-Path -LiteralPath $ttsPlanPath -PathType Leaf
$voiceConfig = $null
$configValid = $false
$defaultVoice = "Unavailable"
$plannedCandidates = @()

if ($configExists) {
    try {
        $voiceConfig = Get-Content -LiteralPath $voiceConfigPath -Raw | ConvertFrom-Json
        $configValid = $true
        $defaultVoiceId = [string]$voiceConfig.default_voice
        $defaultProfile = $voiceConfig.voices | Where-Object { $_.id -eq $defaultVoiceId } | Select-Object -First 1

        if ($null -ne $defaultProfile) {
            $defaultVoice = "$($defaultProfile.display_name) [$defaultVoiceId]"
            $plannedCandidates = @($defaultProfile.future_tts_candidates)
        }
        elseif (-not [string]::IsNullOrWhiteSpace($defaultVoiceId)) {
            $defaultVoice = $defaultVoiceId
        }
    }
    catch {
        $defaultVoice = "Config invalid: $($_.Exception.Message)"
    }
}

$python = Get-CommandDetails -Name "python"
$uv = Get-CommandDetails -Name "uv"
$node = Get-CommandDetails -Name "node"
$npm = Get-CommandDetails -Name "npm"
$ollama = Get-CommandDetails -Name "ollama"

$osDescription = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osDetails = "$($osInfo.Caption) $($osInfo.Version) (build $($osInfo.BuildNumber))"
}
catch {
    $osDetails = "$osDescription (CIM details unavailable)"
}

$audioDevices = @()
$audioDevicesListed = $false
try {
    $audioDevices = @(
        Get-CimInstance -ClassName Win32_SoundDevice |
            Sort-Object Name |
            Select-Object Name, Status
    )
    $audioDevicesListed = $true
}
catch {
    $audioDevicesListed = $false
}

Write-Host ""
Write-Host "Relay TTS Feasibility Check" -ForegroundColor Magenta
Write-Host "Read-only planning check. No audio will be generated." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Environment" -ForegroundColor Cyan
Write-CheckLine -Label "Checked at" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
Write-CheckLine -Label "Repo root" -Value $repoRoot
Write-CheckLine -Label "OS" -Value $osDetails
Write-CheckLine -Label "PowerShell" -Value $PSVersionTable.PSVersion.ToString()
Write-CheckLine -Label "Python" -Value $python.Version
Write-CheckLine -Label "uv" -Value $uv.Version
Write-CheckLine -Label "Node" -Value $node.Version
Write-CheckLine -Label "npm" -Value $npm.Version
Write-CheckLine -Label "Ollama" -Value $(if ($ollama.Available) { $ollama.Version } else { "Not found (optional)" })

Write-Host ""
Write-Host "Relay voice planning" -ForegroundColor Cyan
Write-CheckLine -Label "Voice config exists" -Value $configExists.ToString()
Write-CheckLine -Label "Voice config valid" -Value $configValid.ToString()
Write-CheckLine -Label "TTS plan exists" -Value $planExists.ToString()
Write-CheckLine -Label "Default voice profile" -Value $defaultVoice
Write-CheckLine -Label "Planned TTS candidates" -Value $(if ($plannedCandidates.Count -gt 0) { $plannedCandidates -join ", " } else { "Unavailable" })

Write-Host ""
Write-Host "Candidate command checks" -ForegroundColor Cyan
foreach ($candidate in @("piper", "kokoro")) {
    $candidateCommand = Get-Command $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $candidateCommand) {
        Write-CheckLine -Label $candidate -Value "Available at $($candidateCommand.Source)"
    }
    else {
        Write-CheckLine -Label $candidate -Value "Not installed yet. This is expected during planning."
    }
}

Write-Host ""
Write-Host "Audio output inventory" -ForegroundColor Cyan
if (-not $audioDevicesListed) {
    Write-Host "Audio devices could not be listed through read-only CIM inspection." -ForegroundColor Yellow
}
elseif ($audioDevices.Count -eq 0) {
    Write-Host "No Windows sound devices were reported by CIM." -ForegroundColor Yellow
}
else {
    foreach ($device in $audioDevices) {
        Write-Host ("- {0} [{1}]" -f $device.Name, $device.Status)
    }
}

$missingPrerequisites = @()
if (-not $configExists) { $missingPrerequisites += "Voice profile config" }
if ($configExists -and -not $configValid) { $missingPrerequisites += "Valid voice profile config" }
if (-not $planExists) { $missingPrerequisites += "Relay TTS plan" }
if (-not $python.Available) { $missingPrerequisites += "Python" }
if (-not $uv.Available) { $missingPrerequisites += "uv" }
if (-not $node.Available) { $missingPrerequisites += "Node.js" }
if (-not $npm.Available) { $missingPrerequisites += "npm" }
if (-not $audioDevicesListed) { $missingPrerequisites += "CIM audio-device inventory" }
elseif ($audioDevices.Count -eq 0) { $missingPrerequisites += "Windows sound device" }

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No TTS generated"
Write-Host "- No model downloaded"
Write-Host "- No microphone/audio capture used"
Write-Host "- No OpenClaw modifications made"

Write-Host ""
if ($missingPrerequisites.Count -eq 0) {
    Write-Host "Recommendation: Ready for planning-only TTS prototype" -ForegroundColor Green
}
else {
    Write-Host "Recommendation: Missing prerequisites" -ForegroundColor Yellow
    Write-Host ("Missing: {0}" -f ($missingPrerequisites -join ", ")) -ForegroundColor Yellow
}
