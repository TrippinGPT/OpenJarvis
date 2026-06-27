[CmdletBinding()]
param(
    [switch]$IncludeOllama
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. $PSScriptRoot\relay_stack_control.ps1

$RepoRoot = Get-RelayRepoRoot -ScriptRoot $PSScriptRoot
$FrontendRoot = Join-Path $RepoRoot "frontend"
$State = Read-RelayStackState -RepoRoot $RepoRoot

function Stop-RelayService {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [hashtable]$Entry,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [string[]]$FallbackNeedles
    )

    if (Test-RelayProcessAlive -Entry $Entry) {
        $pidValue = [int]$Entry.pid
        $stopped = Stop-RelayProcessTree -RootPid $pidValue -Label $Label
        $Entry.pid = $null
        $Entry.launched_by_relay = $false
        return $stopped
    }

    $stoppedFallback = Stop-RelayProcessByPortFallback -Port $Port -Label $Label -CommandNeedles $FallbackNeedles
    $Entry.pid = $null
    $Entry.launched_by_relay = $false
    return $stoppedFallback
}

Write-Host "Stopping Trippin AI Relay stack..." -ForegroundColor Magenta
Write-Host "Repo root: $RepoRoot" -ForegroundColor DarkGray

$frontendStopped = Stop-RelayService `
    -Label "Relay frontend" `
    -Entry $State.frontend `
    -Port 5173 `
    -FallbackNeedles @($FrontendRoot, "--port 5173", "vite")

if (-not $frontendStopped) {
    Write-Host "Relay frontend was already stopped or not Relay-owned." -ForegroundColor DarkGray
}

$backendStopped = Stop-RelayService `
    -Label "Relay backend" `
    -Entry $State.backend `
    -Port 8000 `
    -FallbackNeedles @($RepoRoot, "relay serve", "uv")

if (-not $backendStopped) {
    Write-Host "Relay backend was already stopped or not Relay-owned." -ForegroundColor DarkGray
}

if ($IncludeOllama) {
    if ([bool]$State.ollama.launched_by_relay -and (Test-RelayProcessAlive -Entry $State.ollama)) {
        [void](Stop-RelayProcessTree -RootPid ([int]$State.ollama.pid) -Label "Relay-owned Ollama")
        $State.ollama.pid = $null
        $State.ollama.launched_by_relay = $false
    }
    else {
        Write-Host "Skipping Ollama stop because this stack did not record Relay-owned Ollama." -ForegroundColor DarkGray
    }
}
else {
    Write-Host "Ollama left alone. Use -IncludeOllama only when you want to stop Relay-owned Ollama too." -ForegroundColor DarkGray
}

if (-not [bool]$State.ollama.launched_by_relay -and -not $IncludeOllama) {
    $State.ollama.pid = $null
}

if (-not [bool]$State.frontend.launched_by_relay -and -not [bool]$State.backend.launched_by_relay -and -not [bool]$State.ollama.launched_by_relay) {
    Clear-RelayStackState -RepoRoot $RepoRoot
}
else {
    Write-RelayStackState -State $State
}

Write-Host "Relay stop flow complete." -ForegroundColor Green
