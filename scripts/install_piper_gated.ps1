[CmdletBinding()]
param(
    [switch]$AllowInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedRepoRoot = [System.IO.Path]::GetFullPath("D:\AI\TRIPPIN_AI_RELAY")
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$piperRoot = Join-Path $repoRoot "tools\piper"
$venvPath = Join-Path $repoRoot "tools\piper.venv"
$localPython = Join-Path $venvPath "Scripts\python.exe"
$localPiperCommand = Join-Path $venvPath "Scripts\piper.exe"
$runtimeChecker = Join-Path $repoRoot "scripts\check_piper_python_runtime.ps1"
$piperPackage = "piper-tts"
$piperVersion = "1.4.2"

if (-not $repoRoot.Equals($expectedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to inspect or install Piper outside the expected Relay repo: $expectedRepoRoot"
}

function Get-VersionText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return "Not found"
    }

    try {
        $output = & $command.Source --version 2>&1
        $text = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join " "
        if ([string]::IsNullOrWhiteSpace($text)) {
            return "Available (version not reported)"
        }

        return $text
    }
    catch {
        return "Available (version check failed: $($_.Exception.Message))"
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

function Get-Python311Runtime {
    $launcher = Get-Command "py" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $launcher) {
        $previousErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "SilentlyContinue"
            $launcherPath = & $launcher.Source -3.11 -c "import sys; print(sys.executable)" 2>$null
            $launcherExitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        if ($launcherExitCode -eq 0) {
            return [pscustomobject]@{
                Available = $true
                Path = ([string]($launcherPath | Select-Object -First 1)).Trim()
                Method = "Python launcher"
            }
        }

        $inventory = @(& $launcher.Source -0p 2>&1)
        foreach ($inventoryLine in $inventory) {
            $inventoryText = [string]$inventoryLine
            if ($inventoryText -match "3\.11(?:\.\d+)?(?:\s|\*).*?([A-Za-z]:\\.*python\.exe)\s*$") {
                return [pscustomobject]@{
                    Available = $true
                    Path = $Matches[1]
                    Method = "uv-managed Python from launcher inventory"
                }
            }
        }
    }

    return [pscustomobject]@{
        Available = $false
        Path = "Not found"
        Method = "Unavailable"
    }
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & $Command
        $commandExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($commandExitCode -ne 0) {
        throw "$FailureMessage Exit code: $commandExitCode"
    }
}

$uvCommand = Get-Command "uv" -ErrorAction SilentlyContinue | Select-Object -First 1
$python311 = Get-Python311Runtime
$systemPiperCommand = Get-Command "piper" -ErrorAction SilentlyContinue | Select-Object -First 1
$localModuleAvailable = Test-PiperModule -PythonPath $localPython
$venvExists = Test-Path -LiteralPath $localPython -PathType Leaf

if ($python311.Available) {
    $plannedVenvCommand = if ($python311.Method -eq "Python launcher") {
        "py -3.11 -m venv `"$venvPath`""
    }
    else {
        "uv venv --python `"$($python311.Path)`" --seed `"$venvPath`""
    }
}
else {
    $plannedVenvCommand = "Unavailable until Python 3.11 is detected"
}
$plannedInstallCommand = "`"$localPython`" -m pip install --disable-pip-version-check --no-input `"$piperPackage==$piperVersion`""

Write-Host ""
Write-Host "Relay Piper Gated Install" -ForegroundColor Magenta
Write-Host "Repo root: $repoRoot" -ForegroundColor Cyan
Write-Host "Mode: $(if ($AllowInstall) { 'APPROVAL GATE REQUESTED' } else { 'DRY RUN' })" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current status" -ForegroundColor Cyan
Write-Host "- Candidate lane: $piperPackage $piperVersion from OHF-Voice/piper1-gpl"
Write-Host "- Recommended runtime: Python 3.11"
Write-Host "- Python 3.11 detection: $(if ($python311.Available) { "$($python311.Path) [$($python311.Method)]" } else { 'Not found' })"
Write-Host "- System Python: $(Get-VersionText -CommandName 'python')"
Write-Host "- uv: $(Get-VersionText -CommandName 'uv')"
Write-Host "- Planned venv path: $venvPath"
Write-Host "- Local virtual environment: $(if ($venvExists) { $localPython } else { 'Not found' })"
Write-Host "- Local Piper module: $(if ($localModuleAvailable) { 'Available' } else { 'Not found' })"
Write-Host "- Local Piper command: $(if (Test-Path -LiteralPath $localPiperCommand -PathType Leaf) { $localPiperCommand } else { 'Not found' })"
Write-Host "- Global Piper command: $(if ($null -ne $systemPiperCommand) { $systemPiperCommand.Source } else { 'Not installed' })"
Write-Host ""

if (-not $AllowInstall) {
    Write-Host "Dry-run checks only:" -ForegroundColor Yellow
    Write-Host "- Verify the Relay-local Piper sandbox."
    Write-Host "- Verify uv and a compatible Python interpreter."
    Write-Host "- Run the read-only runtime checker: $runtimeChecker"
    Write-Host "- Review the OHF Piper source, package version, GPL license, and Windows compatibility."
    Write-Host "- Planned venv command: $plannedVenvCommand"
    Write-Host "- Planned install command: $plannedInstallCommand"
    Write-Host ""
    Write-Host "Actual installation requires -AllowInstall." -ForegroundColor Yellow
}
else {
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "PIPER INSTALL APPROVAL GATE REQUESTED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Approved scope: create one Python 3.11 venv and install $piperPackage $piperVersion inside it." -ForegroundColor Yellow
    Write-Host "No global install, model download, or audio generation is permitted." -ForegroundColor Yellow
    Write-Host ""

    if (-not $python311.Available) {
        throw "Python 3.11 was not detected. Run the runtime checker and install nothing."
    }
    if ($null -eq $uvCommand -and $python311.Method -ne "Python launcher") {
        throw "uv is required for the detected uv-managed Python 3.11 runtime."
    }
    if ((Test-Path -LiteralPath $venvPath) -and -not $venvExists) {
        throw "The venv path exists but does not contain Scripts\python.exe. Refusing to overwrite or repair it automatically: $venvPath"
    }

    if (-not $venvExists) {
        Write-Host "Venv command: $plannedVenvCommand" -ForegroundColor Cyan
        if ($python311.Method -eq "Python launcher") {
            Invoke-CheckedCommand -FailureMessage "Python 3.11 venv creation failed." -Command {
                & py -3.11 -m venv $venvPath
            }
        }
        else {
            Invoke-CheckedCommand -FailureMessage "uv Python 3.11 venv creation failed." -Command {
                & $uvCommand.Source venv --python $python311.Path --seed $venvPath
            }
        }
    }
    else {
        Write-Host "Existing local venv detected; validating before package install." -ForegroundColor Cyan
    }

    if (-not (Test-Path -LiteralPath $localPython -PathType Leaf)) {
        throw "Local venv Python was not created: $localPython"
    }

    $venvPythonVersion = (& $localPython --version 2>&1 | Select-Object -First 1).ToString()
    if ($venvPythonVersion -notmatch "^Python 3\.11(?:\.|$)") {
        throw "Refusing to install Piper into a non-3.11 venv: $venvPythonVersion"
    }

    Write-Host "Install command: $plannedInstallCommand" -ForegroundColor Cyan
    Invoke-CheckedCommand -FailureMessage "$piperPackage installation failed." -Command {
        & $localPython -m pip install --disable-pip-version-check --no-input "$piperPackage==$piperVersion"
    }

    $pipVersion = (& $localPython -m pip --version 2>&1 | Select-Object -First 1).ToString()
    $installedPiperVersion = (& $localPython -c "from importlib.metadata import version; print(version('piper-tts'))" 2>&1 | Select-Object -First 1).ToString()
    $localModuleAvailable = Test-PiperModule -PythonPath $localPython

    Write-Host ""
    Write-Host "Local install result" -ForegroundColor Green
    Write-Host "- Venv path: $venvPath"
    Write-Host "- Python: $venvPythonVersion"
    Write-Host "- pip: $pipVersion"
    Write-Host "- Piper package: $installedPiperVersion"
    Write-Host "- Piper module detected: $localModuleAvailable"
    Write-Host "- Piper command: $(if (Test-Path -LiteralPath $localPiperCommand -PathType Leaf) { $localPiperCommand } else { 'Package installed; piper.exe not exposed' })"

    if (-not $localModuleAvailable) {
        throw "The Piper package installed, but the piper module could not be imported."
    }
}

Write-Host ""
Write-Host "Safety confirmation" -ForegroundColor Cyan
Write-Host "- Package scope: $(if ($AllowInstall) { "local venv only ($venvPath)" } else { 'no package installed in dry-run mode' })"
Write-Host "- No model downloaded"
Write-Host "- Global Python and global site packages were not modified"
Write-Host "- No audio generated or played"
Write-Host "- No microphone/audio capture used"
Write-Host "- OpenClaw was not touched"
