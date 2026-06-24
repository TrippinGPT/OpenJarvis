[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent $PSScriptRoot
$kokoroPrereqsPath = Join-Path $repoRoot "docs\RELAY_KOKORO_PREREQUISITES.md"
$ttsPlanPath = Join-Path $repoRoot "docs\RELAY_TTS_PLAN.md"
$kokoroPlanPath = Join-Path $repoRoot "docs\RELAY_KOKORO_TTS_PLAN.md"
$voiceProfilesPath = Join-Path $repoRoot "config\relay_voice_profiles.json"
$kokoroToolsPath = Join-Path $repoRoot "tools\kokoro"
$kokoroCachePath = Join-Path $repoRoot "tools\kokoro\models"
$kokoroVenvPath = Join-Path $repoRoot "tools\kokoro.venv"
$kokoroVenvPythonPath = Join-Path $kokoroVenvPath "Scripts\python.exe"
$ttsTestsPath = Join-Path $repoRoot "outputs\tts_tests"
$uvPythonRoot = Join-Path $env:APPDATA "uv\python"
$espeakNgFallbackPath = "C:\Program Files\eSpeak NG\espeak-ng.exe"

function Write-CheckLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Host ("{0,-36} {1}" -f "${Label}:", $Value)
}

function Invoke-OptionalToolCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{
            Available = $false
            Success = $false
            Output = @("Not found")
            Error = $null
            Path = $null
        }
    }

    try {
        $output = @(& $command.Source @Arguments 2>&1)
        return [pscustomobject]@{
            Available = $true
            Success = ($LASTEXITCODE -eq 0)
            Output = $output
            Error = $null
            Path = $command.Source
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $true
            Success = $false
            Output = @()
            Error = $_.Exception.Message
            Path = $command.Source
        }
    }
}

function Invoke-OptionalExecutableCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Available = $false
            Success = $false
            Output = @("Not found")
            Error = $null
            Path = $null
        }
    }

    try {
        $output = @(& $Path @Arguments 2>&1)
        return [pscustomobject]@{
            Available = $true
            Success = ($LASTEXITCODE -eq 0)
            Output = $output
            Error = $null
            Path = $Path
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $true
            Success = $false
            Output = @()
            Error = $_.Exception.Message
            Path = $Path
        }
    }
}

function Get-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $result = Invoke-OptionalToolCommand -Name $Name -Arguments @('--version')
    if (-not $result.Available) {
        return [pscustomobject]@{
            Available = $false
            Path = "Not found"
            Version = "Not found"
        }
    }

    $version = ($result.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($version)) {
        $version = "Available (version not reported)"
    }

    return [pscustomobject]@{
        Available = $true
        Path = $result.Path
        Version = $version
    }
}

function Get-PyZeroInventory {
    $result = Invoke-OptionalToolCommand -Name "py" -Arguments @('-0p')
    $entries = @()

    if ($result.Available) {
        foreach ($line in $result.Output) {
            $text = "$line".Trim()
            if ([string]::IsNullOrWhiteSpace($text) -or -not $text.StartsWith('-V:')) {
                continue
            }

            $payload = $text.Substring(3).Trim()
            $parts = $payload -split '\s+'
            if ($parts.Count -lt 2) {
                continue
            }

            if ($parts[1] -eq '*') {
                $tag = $parts[0]
                $path = $parts[-1]
            }
            else {
                $tag = $parts[0]
                $path = $parts[1]
            }

            $entries += [pscustomobject]@{
                Raw = $text
                Tag = $tag
                Path = $path
            }
        }
    }

    return [pscustomobject]@{
        Available = $result.Available
        Success = $result.Success
        Output = $result.Output
        Entries = $entries
        Error = $result.Error
    }
}

function Get-PythonExecutableInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Exists = $false
            Version = "Missing"
            VersionOk = $false
        }
    }

    try {
        $version = & $Path --version 2>&1 | Select-Object -First 1
        $versionText = if ($null -ne $version) { "$version".Trim() } else { "Available" }
        $versionOk = $versionText -match '^Python\s+3\.11(\.|$)'
    }
    catch {
        $versionText = "Available (version check failed: $($_.Exception.Message))"
        $versionOk = $false
    }

    return [pscustomobject]@{
        Exists = $true
        Version = $versionText
        VersionOk = $versionOk
    }
}

function Get-LatestFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        return $null
    }

    return Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
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
        Get-ChildItem -LiteralPath $Folder -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue
    ).Count
}

function Get-EspeakNgInfo {
    $result = Invoke-OptionalToolCommand -Name "espeak-ng" -Arguments @('--version')
    if (-not $result.Available) {
        if (Test-Path -LiteralPath $espeakNgFallbackPath -PathType Leaf) {
            $result = Invoke-OptionalExecutableCommand -Path $espeakNgFallbackPath -Arguments @('--version')
        }
    }

    if (-not $result.Available) {
        return [pscustomobject]@{
            Available = $false
            Path = "Not found"
            Version = "Not found"
        }
    }

    $version = ($result.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($version)) {
        $version = "Available (version not reported)"
    }

    return [pscustomobject]@{
        Available = $true
        Path = $result.Path
        Version = $version
    }
}

function Get-PipShowStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath,

        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $result = Invoke-OptionalExecutableCommand -Path $PythonPath -Arguments @('-m', 'pip', 'show', $PackageName)
    if (-not $result.Available) {
        return [pscustomobject]@{
            Available = $false
            Installed = $false
            Version = "Not found"
            Path = $PythonPath
            Output = @("Not found")
        }
    }

    $text = ($result.Output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "`n"
    $installed = $result.Success -and ($text -match "(?m)^Name:\s+$([regex]::Escape($PackageName))\s*$")
    $version = "Missing"
    if ($installed -and $text -match "(?m)^Version:\s+(.+)$") {
        $version = $matches[1]
    }

    return [pscustomobject]@{
        Available = $true
        Installed = $installed
        Version = $version
        Path = $PythonPath
        Output = @($result.Output)
    }
}

function Test-GitIgnoredPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    & git -C $repoRoot check-ignore -q -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Add-UniqueCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Candidates,

        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    foreach ($candidate in $Candidates) {
        if ($candidate.Path -ieq $Path) {
            return
        }
    }

    [void]$Candidates.Add([pscustomobject]@{
        Source = $Source
        Path = $Path
    })
}

function Get-UvManagedPython311Candidates {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PyZeroEntries,

        [Parameter(Mandatory = $true)]
        [object[]]$UvListOutput,

        [Parameter(Mandatory = $true)]
        [object[]]$UvFindOutput
    )

    $candidates = New-Object System.Collections.ArrayList

    foreach ($entry in $PyZeroEntries) {
        if ($entry.Tag -match 'Astral/CPython3\.11' -or $entry.Tag -match 'cpython-3\.11' -or $entry.Path -match '\\uv\\python\\cpython-3\.11') {
            Add-UniqueCandidate -Candidates $candidates -Source "py -0p" -Path $entry.Path
        }
    }

    foreach ($line in $UvListOutput) {
        $text = "$line".Trim()
        if ([string]::IsNullOrWhiteSpace($text) -or $text -notmatch '3\.11') {
            continue
        }

        if ($text -match '([A-Za-z]:\\[^"''\r\n]+python\.exe)') {
            Add-UniqueCandidate -Candidates $candidates -Source "uv python list --only-installed" -Path $matches[1]
        }
    }

    foreach ($line in $UvFindOutput) {
        $text = "$line".Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        if ($text -match '([A-Za-z]:\\[^"''\r\n]+python\.exe)') {
            Add-UniqueCandidate -Candidates $candidates -Source "uv python find 3.11" -Path $matches[1]
        }
    }

    if (Test-Path -LiteralPath $uvPythonRoot -PathType Container) {
        $filesystemCandidate = Get-ChildItem -Path (Join-Path $uvPythonRoot 'cpython-3.11*') -Directory -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -ne $filesystemCandidate) {
            $filesystemPython = Join-Path $filesystemCandidate.FullName 'python.exe'
            Add-UniqueCandidate -Candidates $candidates -Source "filesystem fallback" -Path $filesystemPython
        }
    }

    $knownUvPython311 = Join-Path $env:APPDATA 'uv\python\cpython-3.11.15-windows-x86_64-none\python.exe'
    if (Test-Path -LiteralPath $knownUvPython311 -PathType Leaf) {
        Add-UniqueCandidate -Candidates $candidates -Source "known uv path" -Path $knownUvPython311
    }

    $verifiedCandidates = foreach ($candidate in $candidates) {
        $info = Get-PythonExecutableInfo -Path $candidate.Path
        if ($info.Exists -and $info.VersionOk) {
            [pscustomobject]@{
                Source = $candidate.Source
                Path = $candidate.Path
                Version = $info.Version
            }
        }
    }

    return @($verifiedCandidates)
}

$python = Get-CommandVersion -Name "python"
$uv = Get-CommandVersion -Name "uv"
$pip = Get-CommandVersion -Name "pip"
$pyZero = Get-PyZeroInventory
$py311Launcher = Invoke-OptionalToolCommand -Name "py" -Arguments @('-3.11', '--version')
$py311LauncherExecutable = Invoke-OptionalToolCommand -Name "py" -Arguments @('-3.11', '-c', 'import sys; print(sys.executable)')
$py312Version = Invoke-OptionalToolCommand -Name "py" -Arguments @('-3.12', '--version')
$py312Executable = Invoke-OptionalToolCommand -Name "py" -Arguments @('-3.12', '-c', 'import sys; print(sys.executable)')
$uvPythonList = Invoke-OptionalToolCommand -Name "uv" -Arguments @('python', 'list', '--only-installed')
$uvPythonFind = Invoke-OptionalToolCommand -Name "uv" -Arguments @('python', 'find', '3.11')
$espeakNg = Get-EspeakNgInfo

$py311LauncherPath = if ($py311LauncherExecutable.Output.Count -gt 0) { ($py311LauncherExecutable.Output | Select-Object -First 1).ToString().Trim() } else { $null }
$py311LauncherInfo = Get-PythonExecutableInfo -Path $py311LauncherPath
$py311LauncherFound = $py311Launcher.Success -and $py311LauncherInfo.VersionOk

$uvManagedCandidates = Get-UvManagedPython311Candidates -PyZeroEntries $pyZero.Entries -UvListOutput $uvPythonList.Output -UvFindOutput $uvPythonFind.Output
$uvManagedCandidate = $uvManagedCandidates | Select-Object -First 1
$uvManagedFound = $null -ne $uvManagedCandidate
$uvManagedPath = if ($uvManagedFound) { $uvManagedCandidate.Path } else { $null }
$uvManagedInfo = if ($uvManagedFound) { Get-PythonExecutableInfo -Path $uvManagedPath } else { $null }

$selectedPython311Path = $null
$selectedPython311Version = "None"
if ($py311LauncherFound) {
    $selectedPython311Path = $py311LauncherPath
    $selectedPython311Version = $py311LauncherInfo.Version
}
elseif ($uvManagedFound) {
    $selectedPython311Path = $uvManagedPath
    $selectedPython311Version = $uvManagedInfo.Version
}

$python311Ready = $py311LauncherFound -or $uvManagedFound

$defaultPythonPath = if ($python.Available) { $python.Path } else { "Not found" }
$defaultPythonVersion = if ($python.Available) { $python.Version } else { "Not found" }
$kokoroToolsExists = Test-Path -LiteralPath $kokoroToolsPath -PathType Container
$kokoroCacheExists = Test-Path -LiteralPath $kokoroCachePath -PathType Container
$kokoroVenvExists = Test-Path -LiteralPath $kokoroVenvPath -PathType Container
$kokoroVenvPythonExists = Test-Path -LiteralPath $kokoroVenvPythonPath -PathType Leaf
$ttsTestsExists = Test-Path -LiteralPath $ttsTestsPath -PathType Container
$kokoroCacheFileCount = Get-Count -Folder $kokoroCachePath -Filter "*"
$kokoroFirstWavCount = Get-Count -Folder $ttsTestsPath -Filter "relay_kokoro_first_*.wav"
$kokoroLatestWav = Get-LatestFile -Folder $ttsTestsPath -Filter "relay_kokoro_first_*.wav"
$kokoroLatestWavPath = if ($null -ne $kokoroLatestWav) { $kokoroLatestWav.FullName } else { "None" }
$kokoroSweepWavCount = Get-Count -Folder $ttsTestsPath -Filter "relay_kokoro_sweep_*.wav"
$kokoroLatestSweepWav = Get-LatestFile -Folder $ttsTestsPath -Filter "relay_kokoro_sweep_*.wav"
$kokoroLatestSweepWavPath = if ($null -ne $kokoroLatestSweepWav) { $kokoroLatestSweepWav.FullName } else { "None" }
$kokoroVenvPythonInfo = if ($kokoroVenvPythonExists) { Get-PythonExecutableInfo -Path $kokoroVenvPythonPath } else { $null }
$kokoroPackageInfo = if ($kokoroVenvPythonExists) { Get-PipShowStatus -PythonPath $kokoroVenvPythonPath -PackageName "kokoro" } else { $null }

$ignoreChecks = [ordered]@{
    "tools/kokoro.venv/" = (Test-GitIgnoredPattern -Path "tools/kokoro.venv/")
    "tools/kokoro/models/" = (Test-GitIgnoredPattern -Path "tools/kokoro/models/")
    "outputs/tts_tests/*.wav" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.wav")
    "outputs/tts_tests/*.mp3" = (Test-GitIgnoredPattern -Path "outputs/tts_tests/placeholder.mp3")
}

$missingPrerequisites = @()
if (-not $python311Ready) { $missingPrerequisites += "Python 3.11" }
if (-not $uv.Available) { $missingPrerequisites += "uv" }
if (-not $pip.Available) { $missingPrerequisites += "pip" }
if (-not $espeakNg.Available) { $missingPrerequisites += "espeak-ng" }
if (-not $ttsTestsExists) { $missingPrerequisites += "outputs\\tts_tests" }
if (-not $ignoreChecks["tools/kokoro.venv/"]) { $missingPrerequisites += "tools\\kokoro.venv ignore rule" }
if (-not $ignoreChecks["tools/kokoro/models/"]) { $missingPrerequisites += "tools\\kokoro\\models ignore rule" }
if (-not $ignoreChecks["outputs/tts_tests/*.wav"]) { $missingPrerequisites += "WAV ignore rule" }
if (-not $ignoreChecks["outputs/tts_tests/*.mp3"]) { $missingPrerequisites += "MP3 ignore rule" }

Write-Host ""
Write-Host "RELAY KOKORO PREREQUISITE CHECK" -ForegroundColor Magenta
Write-Host "Read-only prep check. No install, no download, no audio." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Environment" -ForegroundColor Cyan
Write-CheckLine -Label "Checked at" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
Write-CheckLine -Label "Repo root" -Value $repoRoot
Write-CheckLine -Label "OS info" -Value ([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)
Write-CheckLine -Label "PowerShell" -Value $PSVersionTable.PSVersion.ToString()
Write-CheckLine -Label "Default Python version" -Value $defaultPythonVersion
Write-CheckLine -Label "Default Python path" -Value $defaultPythonPath
Write-CheckLine -Label "uv" -Value $(if ($uv.Available) { $uv.Version } else { "Not found" })
Write-CheckLine -Label "pip" -Value $(if ($pip.Available) { $pip.Version } else { "Not found" })

Write-Host ""
Write-Host "Python launcher inventory" -ForegroundColor Cyan
if ($pyZero.Available) {
    foreach ($line in $pyZero.Output) {
        if ($null -ne $line -and -not [string]::IsNullOrWhiteSpace("$line")) {
            Write-Host "  $line"
        }
    }
}
else {
    Write-Host "  py launcher not available." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Python 3.11 readiness" -ForegroundColor Cyan
Write-CheckLine -Label "Python 3.11 launcher" -Value $(if ($py311LauncherFound) { "found" } else { "missing" })
Write-CheckLine -Label "Python 3.11 uv-managed" -Value $(if ($uvManagedFound) { "found" } else { "missing" })
Write-CheckLine -Label "Selected Python 3.11 candidate" -Value $(if ($null -ne $selectedPython311Path) { $selectedPython311Path } else { "none" })
Write-CheckLine -Label "Selected Python 3.11 version" -Value $selectedPython311Version

Write-Host ""
Write-Host "Python launcher checks" -ForegroundColor Cyan
Write-CheckLine -Label "py -3.11 --version" -Value $(if ($py311Launcher.Success) { (($py311Launcher.Output | Select-Object -First 1) -as [string]).Trim() } else { "No suitable Python runtime found" })
Write-CheckLine -Label "py -3.11 executable" -Value $(if ($py311LauncherExecutable.Success) { (($py311LauncherExecutable.Output | Select-Object -First 1) -as [string]).Trim() } else { "No suitable Python runtime found" })
Write-CheckLine -Label "py -3.12 --version" -Value $(if ($py312Version.Success) { (($py312Version.Output | Select-Object -First 1) -as [string]).Trim() } else { "No suitable Python runtime found" })
Write-CheckLine -Label "py -3.12 executable" -Value $(if ($py312Executable.Success) { (($py312Executable.Output | Select-Object -First 1) -as [string]).Trim() } else { "No suitable Python runtime found" })

Write-Host ""
Write-Host "uv Python inventory" -ForegroundColor Cyan
Write-CheckLine -Label "uv python list --only-installed" -Value $(if ($uvPythonList.Available) { if ($uvPythonList.Success) { "Ran successfully" } else { "Ran with errors: " + (($uvPythonList.Output | Select-Object -First 1) -as [string]) } } else { "uv not found" })
Write-CheckLine -Label "uv python find 3.11" -Value $(if ($uvPythonFind.Available) { if ($uvPythonFind.Success) { "Ran successfully" } else { "Ran with errors: " + (($uvPythonFind.Output | Select-Object -First 1) -as [string]) } } else { "uv not found" })
if ($uvManagedFound) {
    Write-CheckLine -Label "uv-managed verified path" -Value $uvManagedPath
}

Write-Host ""
Write-Host "Kokoro local paths" -ForegroundColor Cyan
Write-CheckLine -Label "tools\kokoro" -Value $(if ($kokoroToolsExists) { "Present: $kokoroToolsPath" } else { "Missing" })
Write-CheckLine -Label "tools\kokoro\models" -Value $(if ($kokoroCacheExists) { "Present: $kokoroCachePath" } else { "Missing, expected before first WAV test." })
Write-CheckLine -Label "tools\kokoro.venv" -Value $(if ($kokoroVenvExists) { "Present: $kokoroVenvPath" } else { "Missing" })
Write-CheckLine -Label "tools\kokoro.venv\Scripts\python.exe" -Value $(if ($kokoroVenvPythonExists) { "Present: $kokoroVenvPythonPath" } else { "Missing" })
if ($kokoroVenvPythonExists) {
    Write-CheckLine -Label "Venv Python version" -Value $kokoroVenvPythonInfo.Version
    Write-CheckLine -Label "kokoro package in venv" -Value $(if ($kokoroPackageInfo.Installed) { "Installed: kokoro $($kokoroPackageInfo.Version)" } else { "Missing" })
}
else {
    Write-CheckLine -Label "Venv Python version" -Value "Not available"
    Write-CheckLine -Label "kokoro package in venv" -Value "Not checked"
}
Write-CheckLine -Label "Kokoro cache file count" -Value $kokoroCacheFileCount.ToString()
Write-CheckLine -Label "First Kokoro WAV count" -Value $kokoroFirstWavCount.ToString()
Write-CheckLine -Label "Latest Kokoro WAV" -Value $kokoroLatestWavPath
Write-CheckLine -Label "Kokoro sweep WAV count" -Value $kokoroSweepWavCount.ToString()
Write-CheckLine -Label "Latest Kokoro sweep WAV" -Value $kokoroLatestSweepWavPath
Write-CheckLine -Label "Kokoro sweep runner" -Value (Join-Path $repoRoot "scripts\run_kokoro_voice_sweep_gated.ps1")
Write-CheckLine -Label "outputs\tts_tests" -Value $(if ($ttsTestsExists) { "Present: $ttsTestsPath" } else { "Missing" })

Write-Host ""
Write-Host "espeak-ng" -ForegroundColor Cyan
Write-CheckLine -Label "Available" -Value $(if ($espeakNg.Available) { "Yes" } else { "No" })
Write-CheckLine -Label "Path" -Value $espeakNg.Path
Write-CheckLine -Label "Version" -Value $espeakNg.Version

Write-Host ""
Write-Host "Git ignore readiness" -ForegroundColor Cyan
foreach ($item in $ignoreChecks.GetEnumerator()) {
    Write-CheckLine -Label $item.Key -Value $(if ($item.Value) { "Covered" } else { "Not covered" })
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
    Write-Host "Summary: Ready for future gated setup" -ForegroundColor Green
}
else {
    Write-Host "Summary: Blocked by missing prerequisites" -ForegroundColor Yellow
    Write-Host ("Missing: {0}" -f ($missingPrerequisites -join ", ")) -ForegroundColor Yellow
}
