[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "config\relay_project_lanes.json"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Relay bridge manifest not found: $manifestPath"
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}
catch {
    throw "Relay bridge manifest is not valid JSON: $($_.Exception.Message)"
}

foreach ($field in @("relay_name", "openclaw_root", "integration_mode", "lanes")) {
    if ($null -eq $manifest.$field) {
        throw "Relay bridge manifest is missing required field: $field"
    }
}

$openclawRoot = [string]$manifest.openclaw_root

Write-Host ""
Write-Host "Relay/OpenClaw Bridge Check" -ForegroundColor Magenta
Write-Host "Relay:            $($manifest.relay_name)" -ForegroundColor Cyan
Write-Host "OpenClaw root:    $openclawRoot" -ForegroundColor Cyan
Write-Host "Integration mode: $($manifest.integration_mode)" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $openclawRoot -PathType Container)) {
    Write-Warning "OpenClaw folder was not found: $openclawRoot"
}
elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning "Git is not available. OpenClaw repository status checks were skipped."
}
else {
    Write-Host "OpenClaw repository status (read-only)" -ForegroundColor Green

    Write-Host "`n> git status --short" -ForegroundColor DarkGray
    & git -C $openclawRoot status --short

    Write-Host "`n> git branch --show-current" -ForegroundColor DarkGray
    & git -C $openclawRoot branch --show-current

    Write-Host "`n> git --no-pager log --oneline -5" -ForegroundColor DarkGray
    & git -C $openclawRoot --no-pager log --oneline -5
}

Write-Host "`nDeclared project lanes" -ForegroundColor Green
foreach ($lane in $manifest.lanes) {
    Write-Host "`n$($lane.name) [$($lane.status)]" -ForegroundColor Magenta
    Write-Host "Purpose:  $($lane.purpose)"
    Write-Host "Boundary: $($lane.boundary)" -ForegroundColor Yellow
}

Write-Host "`nBridge check complete. No workflows were executed and no files were modified." -ForegroundColor Green
