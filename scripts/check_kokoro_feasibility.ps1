[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$kokoroPlanPath = Join-Path $repoRoot "docs\RELAY_KOKORO_TTS_PLAN.md"
$ttsPlanPath = Join-Path $repoRoot "docs\RELAY_TTS_PLAN.md"
$voiceProfilesPath = Join-Path $repoRoot "config\relay_voice_profiles.json"
$kokoroToolsPath = Join-Path $repoRoot "tools\kokoro"
$kokoroVenvPath = Join-Path $repoRoot "tools\kokoro.venv"
$ttsTestsPath = Join-Path $repoRoot "outputs\tts_tests"
$piperVenvPython = Join-Path $repoRoot "tools\piper.venv\Scripts\python.exe"
$kokoroVenvPython = Join-Path $kokoroVenvPath "Scripts\python.exe"

function Write-CheckLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-34} {1}" -f "${Label}:", $Value)
}

function Get-CommandDetails {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string[]]$Arguments = @("--version")
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{
            Available = $false
            Path = "Not found"
            Version = "Not found"
        }
    }

    try {
        $output = & $command.Source @Arguments 2>&1
        $versionText = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join " "
        if ([string]::IsNullOrWhiteSpace($versionText)) {
            $versionText = "Available (version not reported)"
        }
    }
    catch {
        $versionText = "Available (version check failed: $($_.Exception.Message))"
    }

    return [pscustomobject]@{
        Available = $true
        Path = $command.Source
        Version = $versionText
    }
}

function Get-PythonLauncherInventory {
    $pyCommand = Get-Command py -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $pyCommand) {
        return [pscustomobject]@{
            Available = $false
            Output = @()
            Python311 = "Not found"
            Python312 = "Not found"
        }
    }

    try {
        $output = @(& $pyCommand.Source -0p 2>&1)
    }
    catch {
        $output = @("py launcher check failed: $($_.Exception.Message)")
    }

    $python311 = ($output | Where-Object { $_ -match '3\.11' } | Select-Object -First 1)
    $python312 = ($output | Where-Object { $_ -match '3\.12' } | Select-Object -First 1)

    return [pscustomobject]@{
        Available = $true
        Output = $output
        Python311 = $(if ($null -ne $python311) { "$python311" } else { "Not found" })
        Python312 = $(if ($null -ne $python312) { "$python312" } else { "Not found" })
    }
}

function Get-PythonExecutableInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Exists = $false
            Version = "Missing"
        }
    }

    try {
        $version = & $Path --version 2>&1 | Select-Object -First 1
        $versionText = if ($null -ne $version) { "$version".Trim() } else { "Available" }
    }
    catch {
        $versionText = "Available (version check failed: $($_.Exception.Message))"
    }

    return [pscustomobject]@{
        Exists = $true
        Version = $versionText
    }
}

function Test-KokoroPackageInVenv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath
    )

    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
        return "Python missing"
    }

    try {
        $result = & $PythonPath -c "from importlib.metadata import version; print(version('kokoro'))" 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$result")) {
            return "Installed: $result"
        }
    }
    catch {
        return "Not found"
    }

    return "Not found"
}

function Test-PathStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return "Present: $Path"
    }

    return "Missing"
}

$osDetails = $null
try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osDetails = "$($osInfo.Caption) $($osInfo.Version) (build $($osInfo.BuildNumber))"
}
catch {
    $osDetails = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
}

$python = Get-CommandDetails -Name "python"
$uv = Get-CommandDetails -Name "uv"
$pip = Get-CommandDetails -Name "pip"
$pyInventory = Get-PythonLauncherInventory
$defaultPythonPath = if ($python.Available) { $python.Path } else { "Not found" }
$python311 = if ($pyInventory.Available) { $pyInventory.Python311 } else { "py launcher not available" }
$python312 = if ($pyInventory.Available) { $pyInventory.Python312 } else { "py launcher not available" }
$piperVenvInfo = Get-PythonExecutableInfo -Path $piperVenvPython
$kokoroVenvInfo = Get-PythonExecutableInfo -Path $kokoroVenvPython
$espeakNg = Get-Command espeak-ng -ErrorAction SilentlyContinue | Select-Object -First 1
$ttsTestsExists = Test-Path -LiteralPath $ttsTestsPath -PathType Container
$kokoroRootExists = Test-Path -LiteralPath $kokoroToolsPath -PathType Container
$kokoroVenvExists = Test-Path -LiteralPath $kokoroVenvPath -PathType Container
$voiceProfilesExists = Test-Path -LiteralPath $voiceProfilesPath -PathType Leaf
$kokoroPlanExists = Test-Path -LiteralPath $kokoroPlanPath -PathType Leaf
$ttsPlanExists = Test-Path -LiteralPath $ttsPlanPath -PathType Leaf

$knownVenvReports = @(
    [pscustomobject]@{ Name = "tools\piper.venv"; Python = $piperVenvPython; Kokoro = Test-KokoroPackageInVenv -PythonPath $piperVenvPython },
    [pscustomobject]@{ Name = "tools\kokoro.venv"; Python = $kokoroVenvPython; Kokoro = Test-KokoroPackageInVenv -PythonPath $kokoroVenvPython }
)

$kokoroInstalledInKnownVenvs = $knownVenvReports | Where-Object { $_.Kokoro -like "Installed:*" }

$missingPrerequisites = @()
if (-not $python.Available) { $missingPrerequisites += "Python command" }
if (-not $uv.Available) { $missingPrerequisites += "uv command" }
if (-not $pip.Available) { $missingPrerequisites += "pip command" }
if (-not $ttsTestsExists) { $missingPrerequisites += "outputs\tts_tests folder" }
if (-not $voiceProfilesExists) { $missingPrerequisites += "relay_voice_profiles.json" }
if (-not $kokoroPlanExists) { $missingPrerequisites += "Relay Kokoro TTS plan" }
if (-not $ttsPlanExists) { $missingPrerequisites += "Relay TTS plan" }
if (-not ($pyInventory.Python311 -ne "Not found" -or $pyInventory.Python312 -ne "Not found" -or $piperVenvInfo.Exists -or $kokoroVenvInfo.Exists)) {
    $missingPrerequisites += "Python 3.11 or 3.12 support"
}
if ($null -eq $espeakNg) { $missingPrerequisites += "espeak-ng on PATH" }

Write-Host ""
Write-Host "RELAY KOKORO FEASIBILITY CHECK" -ForegroundColor Magenta
Write-Host "Read-only planning check. No Kokoro install, download, or audio generation will occur." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Environment" -ForegroundColor Cyan
Write-CheckLine -Label "Checked at" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
Write-CheckLine -Label "Repo root" -Value $repoRoot
Write-CheckLine -Label "OS" -Value $osDetails
Write-CheckLine -Label "PowerShell" -Value $PSVersionTable.PSVersion.ToString()
Write-CheckLine -Label "Default Python" -Value $(if ($python.Available) { $python.Version } else { "Not found" })
Write-CheckLine -Label "Default Python path" -Value $defaultPythonPath
Write-CheckLine -Label "uv" -Value $(if ($uv.Available) { $uv.Version } else { "Not found" })
Write-CheckLine -Label "pip" -Value $(if ($pip.Available) { $pip.Version } else { "Not found" })

Write-Host ""
Write-Host "Python launcher inventory" -ForegroundColor Cyan
if ($pyInventory.Available) {
    Write-CheckLine -Label "Python 3.11" -Value $python311
    Write-CheckLine -Label "Python 3.12" -Value $python312
    foreach ($line in $pyInventory.Output) {
        if ($null -ne $line -and -not [string]::IsNullOrWhiteSpace("$line")) {
            Write-Host "  $line"
        }
    }
}
else {
    Write-Host "py launcher not available." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Kokoro local sandbox" -ForegroundColor Cyan
Write-CheckLine -Label "tools\kokoro" -Value (Test-PathStatus -Path $kokoroToolsPath)
Write-CheckLine -Label "tools\kokoro.venv" -Value (Test-PathStatus -Path $kokoroVenvPath)
Write-CheckLine -Label "Kokoro package in tools\piper.venv" -Value (Test-KokoroPackageInVenv -PythonPath $piperVenvPython)
Write-CheckLine -Label "Kokoro package in tools\kokoro.venv" -Value (Test-KokoroPackageInVenv -PythonPath $kokoroVenvPython)
Write-CheckLine -Label "espeak-ng" -Value $(if ($null -ne $espeakNg) { $espeakNg.Source } else { "Not found on PATH" })

Write-Host ""
Write-Host "Planning folders" -ForegroundColor Cyan
Write-CheckLine -Label "outputs\tts_tests" -Value $(if ($ttsTestsExists) { "Present: $ttsTestsPath" } else { "Missing" })
Write-CheckLine -Label "Relay TTS plan" -Value $(if ($ttsPlanExists) { "Present" } else { "Missing" })
Write-CheckLine -Label "Kokoro plan" -Value $(if ($kokoroPlanExists) { "Present" } else { "Missing" })
Write-CheckLine -Label "relay_voice_profiles.json" -Value $(if ($voiceProfilesExists) { "Present" } else { "Missing" })

Write-Host ""
Write-Host "Known local venv inventory" -ForegroundColor Cyan
foreach ($report in $knownVenvReports) {
    Write-CheckLine -Label $report.Name -Value $report.Kokoro
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- No folders created"
Write-Host "- No packages installed"
Write-Host "- No models downloaded"
Write-Host "- No audio generated"
Write-Host "- No audio played"
Write-Host "- No microphone/audio capture used"
Write-Host "- No remote APIs called"
Write-Host "- No OpenClaw changes made"

Write-Host ""
if ($missingPrerequisites.Count -eq 0) {
    Write-Host "Recommendation: Ready for Kokoro planning-only setup" -ForegroundColor Green
}
else {
    Write-Host "Recommendation: Missing prerequisites" -ForegroundColor Yellow
    Write-Host ("Missing: {0}" -f ($missingPrerequisites -join ", ")) -ForegroundColor Yellow
}
