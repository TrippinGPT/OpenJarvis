[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$launcherPath = "D:\AI\TRIPPIN_AI_RELAY\scripts\start_relay_stack.ps1"
$powerShellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$desktopPath = [Environment]::GetFolderPath("Desktop")

if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "Relay stack launcher not found: $launcherPath"
}

if (-not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
    throw "Windows PowerShell not found: $powerShellPath"
}

if ([string]::IsNullOrWhiteSpace($desktopPath) -or
    -not (Test-Path -LiteralPath $desktopPath -PathType Container)) {
    throw "Unable to resolve the current user's desktop folder."
}

$shortcutPath = Join-Path $desktopPath "Trippin AI Relay.lnk"
$workingDirectory = Split-Path -Parent (Split-Path -Parent $launcherPath)

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShellPath
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcherPath`""
$shortcut.WorkingDirectory = $workingDirectory
$shortcut.Description = "Start the Trippin AI Relay local command center"
$shortcut.IconLocation = "$powerShellPath,0"
$shortcut.Save()

if (-not (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) {
    throw "Shortcut was not created: $shortcutPath"
}

Write-Host "Created desktop shortcut: $shortcutPath" -ForegroundColor Green
