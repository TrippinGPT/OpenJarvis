[CmdletBinding()]
param(
    [int]$OllamaTimeoutSeconds = 90,
    [int]$BackendTimeoutSeconds = 180,
    [int]$FrontendTimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$FrontendRoot = Join-Path $RepoRoot "frontend"
$OllamaReadyUri = "http://127.0.0.1:11434/api/version"
$BackendReadyUri = "http://127.0.0.1:8000/health"
$FrontendReadyUri = "http://127.0.0.1:5173/"

function Get-CommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }

    if (-not [string]::IsNullOrWhiteSpace($command.Source)) {
        return $command.Source
    }

    if (-not [string]::IsNullOrWhiteSpace($command.Path)) {
        return $command.Path
    }

    return $command.Definition
}

function Test-HttpReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Uri -TimeoutSec 5
        return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300)
    }
    catch {
        return $false
    }
}

function Wait-HttpReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [int]$TimeoutSeconds,

        [System.Diagnostics.Process]$ProcessHandle
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    Write-Host "Waiting for $Label..." -ForegroundColor Yellow
    while ((Get-Date) -lt $deadline) {
        if ($ProcessHandle -and $ProcessHandle.HasExited) {
            throw "$Label process exited early with code $($ProcessHandle.ExitCode)."
        }

        if (Test-HttpReady -Uri $Uri) {
            Write-Host "$Label is ready." -ForegroundColor Green
            return $true
        }

        Start-Sleep -Seconds 2
    }

    return $false
}

function Start-RelayShellCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [string]$CommandText
    )

    Write-Host "Starting $Label..." -ForegroundColor Cyan
    $powershellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $argumentList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command",
        $CommandText
    )

    return Start-Process `
        -FilePath $powershellPath `
        -ArgumentList $argumentList `
        -WorkingDirectory $WorkingDirectory `
        -WindowStyle Hidden `
        -PassThru
}

function Invoke-DesktopBrowserOpen {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    try {
        Start-Process $Uri
        return $true
    }
    catch {
        Write-Warning "Could not open the browser automatically. Open this URL manually: $Uri"
        return $false
    }
}

Write-Host "Starting Trippin AI Relay stack..." -ForegroundColor Magenta
Write-Host "Repo root: $RepoRoot" -ForegroundColor DarkGray

if (-not (Test-HttpReady -Uri $OllamaReadyUri)) {
    $ollamaPath = Get-CommandPath -Name "ollama"
    if ([string]::IsNullOrWhiteSpace($ollamaPath)) {
        throw "Ollama is not reachable at $OllamaReadyUri and 'ollama' is not on PATH."
    }

    $ollamaProcess = Start-RelayShellCommand `
        -Label "Ollama" `
        -WorkingDirectory $RepoRoot `
        -CommandText "Set-Location -LiteralPath '$RepoRoot'; & '$ollamaPath' serve"

    if (-not (Wait-HttpReady -Uri $OllamaReadyUri -Label "Ollama" -TimeoutSeconds $OllamaTimeoutSeconds -ProcessHandle $ollamaProcess)) {
        throw "Ollama did not become ready within $OllamaTimeoutSeconds seconds."
    }
}
else {
    Write-Host "Ollama is already ready." -ForegroundColor Green
}

if (-not (Test-HttpReady -Uri $BackendReadyUri)) {
    $uvPath = Get-CommandPath -Name "uv"
    if ([string]::IsNullOrWhiteSpace($uvPath)) {
        throw "'uv' is not available on PATH."
    }

    $backendProcess = Start-RelayShellCommand `
        -Label "Relay backend" `
        -WorkingDirectory $RepoRoot `
        -CommandText "Set-Location -LiteralPath '$RepoRoot'; & '$uvPath' run relay serve"

    if (-not (Wait-HttpReady -Uri $BackendReadyUri -Label "Relay backend" -TimeoutSeconds $BackendTimeoutSeconds -ProcessHandle $backendProcess)) {
        throw "Relay backend did not become ready within $BackendTimeoutSeconds seconds."
    }
}
else {
    Write-Host "Relay backend is already ready." -ForegroundColor Green
}

if (-not (Test-HttpReady -Uri $FrontendReadyUri)) {
    $npmPath = Get-CommandPath -Name "npm"
    if ([string]::IsNullOrWhiteSpace($npmPath)) {
        throw "'npm' is not available on PATH."
    }

    $frontendProcess = Start-RelayShellCommand `
        -Label "Relay frontend" `
        -WorkingDirectory $FrontendRoot `
        -CommandText "Set-Location -LiteralPath '$FrontendRoot'; & '$npmPath' run dev -- --host 127.0.0.1 --port 5173"

    if (-not (Wait-HttpReady -Uri $FrontendReadyUri -Label "Relay frontend" -TimeoutSeconds $FrontendTimeoutSeconds -ProcessHandle $frontendProcess)) {
        throw "Relay frontend did not become ready within $FrontendTimeoutSeconds seconds."
    }
}
else {
    Write-Host "Relay frontend is already ready." -ForegroundColor Green
}

Write-Host "Relay stack is ready." -ForegroundColor Green
Write-Host "Backend:  $BackendReadyUri" -ForegroundColor Cyan
Write-Host "Frontend: $FrontendReadyUri" -ForegroundColor Cyan

Invoke-DesktopBrowserOpen -Uri $FrontendReadyUri | Out-Null
