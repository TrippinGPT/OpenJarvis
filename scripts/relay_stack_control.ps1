[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RelayRepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot
    )

    return Split-Path -Parent $ScriptRoot
}

function Get-RelayStackStatePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    return Join-Path $RepoRoot ".relay-stack-state.json"
}

function New-RelayStackState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    return @{
        repo_root = $RepoRoot
        updated_at = (Get-Date).ToString("o")
        frontend = @{
            pid = $null
            launched_by_relay = $false
        }
        backend = @{
            pid = $null
            launched_by_relay = $false
        }
        ollama = @{
            pid = $null
            launched_by_relay = $false
        }
    }
}

function Read-RelayStackState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $path = Get-RelayStackStatePath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return (New-RelayStackState -RepoRoot $RepoRoot)
    }

    try {
        $raw = Get-Content -LiteralPath $path -Raw
        $parsed = $raw | ConvertFrom-Json -AsHashtable
        if ($null -eq $parsed) {
            return (New-RelayStackState -RepoRoot $RepoRoot)
        }

        $state = New-RelayStackState -RepoRoot $RepoRoot
        foreach ($key in @("frontend", "backend", "ollama")) {
            if ($parsed.ContainsKey($key) -and $parsed[$key] -is [System.Collections.IDictionary]) {
                $state[$key]["pid"] = $parsed[$key]["pid"]
                $state[$key]["launched_by_relay"] = [bool]$parsed[$key]["launched_by_relay"]
            }
        }

        if ($parsed.ContainsKey("updated_at")) {
            $state["updated_at"] = $parsed["updated_at"]
        }

        return $state
    }
    catch {
        return (New-RelayStackState -RepoRoot $RepoRoot)
    }
}

function Write-RelayStackState {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $path = Get-RelayStackStatePath -RepoRoot $State.repo_root
    $State.updated_at = (Get-Date).ToString("o")
    $json = $State | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $path -Value $json -Encoding utf8
}

function Clear-RelayStackState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $path = Get-RelayStackStatePath -RepoRoot $RepoRoot
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
    }
}

function Get-RelayProcessRecord {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    return Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
}

function Test-RelayProcessAlive {
    param(
        [AllowNull()]
        [object]$Entry
    )

    if ($null -eq $Entry) {
        return $false
    }

    $pidValue = 0
    if ($Entry -is [System.Collections.IDictionary]) {
        if ($Entry.Contains("pid") -and $null -ne $Entry["pid"]) {
            $pidValue = [int]$Entry["pid"]
        }
    }
    else {
        if ($null -ne $Entry.pid) {
            $pidValue = [int]$Entry.pid
        }
    }

    if ($pidValue -le 0) {
        return $false
    }

    return ($null -ne (Get-RelayProcessRecord -ProcessId $pidValue))
}

function Get-RelayDescendantProcessIds {
    param(
        [Parameter(Mandatory = $true)]
        [int]$RootPid
    )

    $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $childrenByParent = @{}
    foreach ($proc in $all) {
        if (-not $childrenByParent.ContainsKey($proc.ParentProcessId)) {
            $childrenByParent[$proc.ParentProcessId] = New-Object System.Collections.Generic.List[int]
        }
        $childrenByParent[$proc.ParentProcessId].Add([int]$proc.ProcessId)
    }

    $result = New-Object System.Collections.Generic.List[int]
    $queue = New-Object System.Collections.Generic.Queue[int]
    $queue.Enqueue($RootPid)

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($result.Contains($current)) {
            continue
        }
        $result.Add($current)
        if ($childrenByParent.ContainsKey($current)) {
            foreach ($child in $childrenByParent[$current]) {
                $queue.Enqueue($child)
            }
        }
    }

    return [int[]]$result
}

function Stop-RelayProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [int]$RootPid,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $targets = Get-RelayDescendantProcessIds -RootPid $RootPid | Sort-Object -Descending
    $stopped = $false
    foreach ($targetPid in $targets) {
        $proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
        if ($null -eq $proc) {
            continue
        }
        Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
        $stopped = $true
    }

    if ($stopped) {
        Write-Host "Stopped $Label." -ForegroundColor Green
    }

    return $stopped
}

function Get-RelayPortOwnerPid {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $connection) {
        return $null
    }
    return [int]$connection.OwningProcess
}

function Test-RelayCommandLineMatch {
    param(
        [AllowNull()]
        [string]$CommandLine,

        [Parameter(Mandatory = $true)]
        [string[]]$Needles
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    foreach ($needle in $Needles) {
        if ($CommandLine.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Stop-RelayProcessByPortFallback {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string[]]$CommandNeedles
    )

    $ownerPid = Get-RelayPortOwnerPid -Port $Port
    if ($null -eq $ownerPid) {
        Write-Host "$Label is not listening on port $Port." -ForegroundColor DarkGray
        return $false
    }

    $record = Get-RelayProcessRecord -ProcessId $ownerPid
    if ($null -eq $record) {
        Write-Host "$Label owner PID $ownerPid is already gone." -ForegroundColor DarkGray
        return $false
    }

    if (-not (Test-RelayCommandLineMatch -CommandLine $record.CommandLine -Needles $CommandNeedles)) {
        Write-Warning "Skipping $Label on port $Port because the owning process did not match the expected Relay command line."
        return $false
    }

    return (Stop-RelayProcessTree -RootPid $ownerPid -Label $Label)
}
