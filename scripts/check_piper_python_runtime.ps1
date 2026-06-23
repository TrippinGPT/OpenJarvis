[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedRepoRoot = [System.IO.Path]::GetFullPath("D:\AI\TRIPPIN_AI_RELAY")
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$piperSandbox = Join-Path $repoRoot "tools\piper"
$futureVenv = Join-Path $repoRoot "tools\piper.venv"
$futureVenvPython = Join-Path $futureVenv "Scripts\python.exe"

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to inspect Piper runtimes outside the expected Relay repo: $expectedRepoRoot"
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
            Path = "Not found"
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
        Path = $command.Source
        Version = $version
    }
}

function Test-PythonLauncherRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $launcher = Get-Command "py" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $launcher) {
        return [pscustomobject]@{
            Version = $Version
            Available = $false
            Path = "Python launcher not found"
        }
    }

    $selector = "-$Version"
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "SilentlyContinue"
        $output = & $launcher.Source $selector -c "import sys; print(sys.executable)" 2>$null
        $launcherExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($launcherExitCode -ne 0) {
        $versionPattern = [regex]::Escape($Version)
        foreach ($inventoryLine in $script:launcherInventory) {
            $inventoryText = [string]$inventoryLine
            if ($inventoryText -match "$versionPattern(?:\.\d+)?(?:\s|\*).*?([A-Za-z]:\\.*python\.exe)\s*$") {
                return [pscustomobject]@{
                    Version = $Version
                    Available = $true
                    Path = $Matches[1]
                }
            }
        }

        return [pscustomobject]@{
            Version = $Version
            Available = $false
            Path = "Not installed"
        }
    }

    return [pscustomobject]@{
        Version = $Version
        Available = $true
        Path = (($output | Select-Object -First 1) -as [string]).Trim()
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

$defaultPython = Get-CommandVersion -Name "python"
$uv = Get-CommandVersion -Name "uv"
$pythonLauncher = Get-Command "py" -ErrorAction SilentlyContinue | Select-Object -First 1
$launcherInventory = @()

if ($null -ne $pythonLauncher) {
    try {
        $launcherInventory = @(& $pythonLauncher.Source -0p 2>&1)
    }
    catch {
        $launcherInventory = @("Python launcher inventory failed: $($_.Exception.Message)")
    }
}

$runtimes = @(
    Test-PythonLauncherRuntime -Version "3.11"
    Test-PythonLauncherRuntime -Version "3.12"
    Test-PythonLauncherRuntime -Version "3.13"
    Test-PythonLauncherRuntime -Version "3.14"
)

$python311 = $runtimes | Where-Object Version -eq "3.11" | Select-Object -First 1
$python312 = $runtimes | Where-Object Version -eq "3.12" | Select-Object -First 1
$python313 = $runtimes | Where-Object Version -eq "3.13" | Select-Object -First 1
$python314 = $runtimes | Where-Object Version -eq "3.14" | Select-Object -First 1

if (Test-Path -LiteralPath $futureVenvPython -PathType Leaf) {
    $venvPythonVersion = (& $futureVenvPython --version 2>&1 | Select-Object -First 1).ToString()
    $recommendation = "Relay-local Piper venv is present: $venvPythonVersion"
    $nextSafeCommand = "powershell -ExecutionPolicy Bypass -File `"$repoRoot\scripts\check_piper_setup.ps1`""
}
elseif ($python311.Available) {
    $recommendation = "Preferred: Python 3.11 local venv"
    $nextSafeCommand = "uv venv --python 3.11 `"$futureVenv`""
}
elseif ($python312.Available) {
    $recommendation = "Acceptable: Python 3.12 local venv"
    $nextSafeCommand = "uv venv --python 3.12 `"$futureVenv`""
}
elseif ($python313.Available -or $python314.Available) {
    $recommendation = "Python 3.13/3.14 detected only. Keep Piper install disabled until compatibility is confirmed or a supported local runtime is installed manually."
    $nextSafeCommand = "After manually installing an approved Python 3.11 runtime: uv venv --python 3.11 `"$futureVenv`""
}
else {
    $recommendation = "No supported candidate runtime detected. Keep Piper install disabled."
    $nextSafeCommand = "After manually installing an approved Python 3.11 runtime: uv venv --python 3.11 `"$futureVenv`""
}

Write-Host ""
Write-Host "RELAY PIPER PYTHON RUNTIME CHECK" -ForegroundColor Magenta
Write-Host "Read-only compatibility inventory. No runtime will be installed or created." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Runtime inventory" -ForegroundColor Cyan
Write-CheckLine -Label "Repo root" -Value $repoRoot
Write-CheckLine -Label "PowerShell" -Value $PSVersionTable.PSVersion.ToString()
Write-CheckLine -Label "Default Python" -Value $defaultPython.Version
Write-CheckLine -Label "Default Python path" -Value $defaultPython.Path
Write-CheckLine -Label "Python launcher" -Value $(if ($null -ne $pythonLauncher) { $pythonLauncher.Source } else { "Not found" })

Write-Host ""
Write-Host "py -0p" -ForegroundColor Cyan
if ($launcherInventory.Count -eq 0) {
    Write-Host "Python launcher not found or no runtimes reported."
}
else {
    foreach ($line in $launcherInventory) {
        Write-Host $line
    }
}

Write-Host ""
Write-Host "Candidate runtimes" -ForegroundColor Cyan
foreach ($runtime in $runtimes) {
    Write-CheckLine -Label "Python $($runtime.Version)" -Value $(if ($runtime.Available) { "Installed: $($runtime.Path)" } else { $runtime.Path })
}
Write-CheckLine -Label "uv" -Value $(if ($uv.Available) { "$($uv.Version) [$($uv.Path)]" } else { "Not found" })
Write-CheckLine -Label "Piper sandbox" -Value $(if (Test-Path -LiteralPath $piperSandbox -PathType Container) { "Present: $piperSandbox" } else { "Missing: $piperSandbox" })
Write-CheckLine -Label "Piper venv path" -Value $(if (Test-Path -LiteralPath $futureVenv -PathType Container) { "Present: $futureVenv" } else { "Not created: $futureVenv" })

Write-Host ""
Write-Host "Candidate recommendation" -ForegroundColor Cyan
Write-Host $recommendation -ForegroundColor Yellow

Write-Host ""
Write-Host "Next safe command (documentation only; do not run without approval)" -ForegroundColor Cyan
Write-Host $nextSafeCommand

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "No install occurred."
Write-Host "No download occurred."
Write-Host "No virtual environment was created."
Write-Host "No audio was generated."
Write-Host "No OpenClaw changes made."
