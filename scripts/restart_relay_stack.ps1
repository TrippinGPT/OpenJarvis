[CmdletBinding()]
param(
    [switch]$IncludeOllama,
    [int]$OllamaTimeoutSeconds = 90,
    [int]$BackendTimeoutSeconds = 180,
    [int]$FrontendTimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$stopScript = Join-Path $PSScriptRoot "stop_relay_stack.ps1"
$startScript = Join-Path $PSScriptRoot "start_relay_stack.ps1"

if (-not (Test-Path -LiteralPath $stopScript -PathType Leaf)) {
    throw "Stop script not found: $stopScript"
}

if (-not (Test-Path -LiteralPath $startScript -PathType Leaf)) {
    throw "Start script not found: $startScript"
}

Write-Host "Restarting Trippin AI Relay stack..." -ForegroundColor Magenta

if ($IncludeOllama) {
    & $stopScript -IncludeOllama
}
else {
    & $stopScript
}

Start-Sleep -Seconds 2

& $startScript `
    -OllamaTimeoutSeconds $OllamaTimeoutSeconds `
    -BackendTimeoutSeconds $BackendTimeoutSeconds `
    -FrontendTimeoutSeconds $FrontendTimeoutSeconds
