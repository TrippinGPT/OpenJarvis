[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Line,

    [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
    [string]$Mode = 'neutral'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-SmartmouthEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [ValidateSet('none', 'slight', 'caps')]
        [string]$Emphasis = 'none',

        [ValidateSet('none', 'short', 'medium', 'long')]
        [string]$PauseAfter = 'none'
    )

    return [pscustomobject]@{
        Text = $Text
        PauseAfter = $PauseAfter
        Emphasis = $Emphasis
    }
}

function Normalize-SmartmouthText {
    param([Parameter(Mandatory = $true)][string]$Text)

    $normalized = $Text -replace '[\u2018\u2019]', "'" -replace '[\u201C\u201D]', '"'
    $normalized = $normalized -replace '\s+', ' '
    return $normalized.Trim()
}

function Remove-SmartmouthFillers {
    param([Parameter(Mandatory = $true)][string]$Text)

    $result = $Text
    $result = $result -replace '\bin progress\b', ''
    $result = $result -replace '\bcurrently\b', ''
    $result = $result -replace '\bat this time\b', ''
    $result = $result -replace '\bwe are now\b', ''
    $result = $result -replace '\bthat\b(?=\s+(?:now|we|this|there|is|are|was|were|plan|step|move|route|go|means|looks|feels|sounds?|needs?|can|will|should|I|it))', ''
    $result = $result -replace '\bjust\b(?=\s+(?:need|need to|have|need a|need an))', ''
    $result = $result -replace '\s+', ' '
    return $result.Trim()
}

function Get-SarcasticLineCap {
    return 3
}

function Add-TerminalPunctuation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [ValidateSet('none', 'short', 'medium', 'long')]
        [string]$PauseAfter = 'none'
    )

    $trimmed = [regex]::Replace($Text.Trim(), '[.!?]+$', '')
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $null
    }

    switch ($PauseAfter) {
        'short' { return "$trimmed." }
        'medium' { return "$trimmed..." }
        'long' { return "$trimmed... ..." }
        default { return "$trimmed." }
    }
}

function Set-SentenceCase {
    param([Parameter(Mandatory = $true)][string]$Text)

    $trimmed = $Text.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $null
    }

    if ($trimmed.Length -eq 1) {
        return $trimmed.ToUpperInvariant()
    }

    return ($trimmed.Substring(0, 1).ToUpperInvariant() + $trimmed.Substring(1))
}

function Split-ChunkedLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [int]$MaxWords = 6
    )

    $clean = $Text.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return @()
    }

    $subChunks = @()
    foreach ($piece in ($clean -split '\s*(?:,|;|:)\s*')) {
        $trimmedPiece = $piece.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedPiece)) {
            continue
        }

        $words = @($trimmedPiece -split '\s+')
        if ($words.Count -le $MaxWords) {
            $subChunks += $trimmedPiece
            continue
        }

        $buffer = New-Object System.Collections.Generic.List[string]
        foreach ($word in $words) {
            [void]$buffer.Add($word)
            if ($buffer.Count -ge $MaxWords) {
                $subChunks += ($buffer -join ' ')
                $buffer.Clear()
            }
        }

        if ($buffer.Count -gt 0) {
            $subChunks += ($buffer -join ' ')
        }
    }

    return $subChunks
}

function Apply-Emphasis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
        [string]$Mode,

        [ValidateSet('none', 'slight', 'caps')]
        [string]$Emphasis = 'none'
    )

    if ($Mode -notin @('sarcastic', 'command')) {
        return $Text
    }

    $candidateMap = switch ($Mode) {
        'sarcastic' { @('have', 'now', 'plan', 'ruin', 'stop', 'actually') }
        'command' { @('stay', 'stop', 'now', 'task', 'route', 'move', 'go') }
        default { @() }
    }

    if ($candidateMap.Count -eq 0) {
        return $Text
    }

    if ($Emphasis -eq 'caps') {
        foreach ($candidate in $candidateMap) {
            $pattern = "(?i)\b$([regex]::Escape($candidate))\b"
            if ($Text -match $pattern) {
                return [regex]::Replace($Text, $pattern, { param($m) $m.Value.ToUpperInvariant() }, 1)
            }
        }
    }

    if ($Emphasis -eq 'slight') {
        return $Text
    }

    return $Text
}

function Get-ModeSpecificSmartmouthEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    $normalized = ($Text -replace '[.!?]+', '.').ToLowerInvariant().Trim()
    $normalized = Remove-SmartmouthFillers -Text $normalized

    if ($normalized -match '^routing now\.?\s*shocking development:\s*we are using a plan\.?$') {
        switch ($Mode) {
            'dry' {
                return @(
                    (New-SmartmouthEntry -Text 'Routing now.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'We actually have a plan.' -PauseAfter 'medium' -Emphasis 'slight')
                )
            }
            'sarcastic' {
                return @(
                    (New-SmartmouthEntry -Text 'Routing now.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'We have a plan.' -PauseAfter 'none' -Emphasis 'caps'),
                    (New-SmartmouthEntry -Text 'Try not to ruin it.' -PauseAfter 'medium')
                )
            }
            'command' {
                return @(
                    (New-SmartmouthEntry -Text 'Routing now.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Stay on task.' -PauseAfter 'none' -Emphasis 'slight')
                )
            }
            default {
                return @(
                    (New-SmartmouthEntry -Text 'Routing now.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Shocking development.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'We are using a plan.' -PauseAfter 'medium')
                )
            }
        }
    }

    if ($normalized -match '^relay online\.?\s*try not to break anything expensive\.?$') {
        switch ($Mode) {
            'dry' {
                return @(
                    (New-SmartmouthEntry -Text 'Relay online.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Try not to break anything expensive.' -PauseAfter 'medium')
                )
            }
            'sarcastic' {
                return @(
                    (New-SmartmouthEntry -Text 'Relay online.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Try not to break anything expensive.' -PauseAfter 'medium')
                )
            }
            'command' {
                return @(
                    (New-SmartmouthEntry -Text 'Relay online.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Do not break expensive things.' -PauseAfter 'none' -Emphasis 'slight')
                )
            }
            default {
                return @(
                    (New-SmartmouthEntry -Text 'Relay online.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Try not to break anything expensive.' -PauseAfter 'medium')
                )
            }
        }
    }

    if ($normalized -match '^i can make this faster, cleaner, and less cursed\.?$') {
        switch ($Mode) {
            'dry' {
                return @(
                    (New-SmartmouthEntry -Text 'I can make this faster.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Cleaner.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Less cursed.' -PauseAfter 'medium')
                )
            }
            'sarcastic' {
                return @(
                    (New-SmartmouthEntry -Text 'I can make this faster.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Cleaner.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Less cursed.' -PauseAfter 'medium')
                )
            }
            'command' {
                return @(
                    (New-SmartmouthEntry -Text 'Make it faster.' -PauseAfter 'short' -Emphasis 'slight'),
                    (New-SmartmouthEntry -Text 'Keep it clean.' -PauseAfter 'short' -Emphasis 'slight'),
                    (New-SmartmouthEntry -Text 'Keep it less cursed.' -PauseAfter 'none')
                )
            }
            default {
                return @(
                    (New-SmartmouthEntry -Text 'I can make this faster.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Cleaner.' -PauseAfter 'short'),
                    (New-SmartmouthEntry -Text 'Less cursed.' -PauseAfter 'medium')
                )
            }
        }
    }

    if ($Mode -eq 'sarcastic') {
        if ($normalized -match '^routing now\.?\s*we have a plan\.?\s*try not to ruin it\.?$') {
            return @(
                (New-SmartmouthEntry -Text 'Routing now.' -PauseAfter 'short'),
                (New-SmartmouthEntry -Text 'We HAVE a plan.' -PauseAfter 'none' -Emphasis 'caps'),
                (New-SmartmouthEntry -Text 'Try not to ruin it.' -PauseAfter 'medium')
            )
        }

        if ($normalized -match "^routing now\.?\s*don'?t screw it up\.?$") {
            return @(
                (New-SmartmouthEntry -Text 'Routing now.' -PauseAfter 'short'),
                (New-SmartmouthEntry -Text "Don't screw it up." -PauseAfter 'medium' -Emphasis 'slight')
            )
        }

        if ($normalized -match '^we have a plan\.?\s*miracles happen\.?$') {
            return @(
                (New-SmartmouthEntry -Text 'We HAVE a plan.' -PauseAfter 'short' -Emphasis 'caps'),
                (New-SmartmouthEntry -Text 'Miracles happen.' -PauseAfter 'medium')
            )
        }

        if ($normalized -match '^relax\.?\s*i already fixed it\.?$') {
            return @(
                (New-SmartmouthEntry -Text 'Relax.' -PauseAfter 'short'),
                (New-SmartmouthEntry -Text 'I already fixed it.' -PauseAfter 'medium')
            )
        }
    }

    return $null
}

function Get-ModeDefaultPause {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [int]$Index,

        [Parameter(Mandatory = $true)]
        [int]$Total
    )

    if ($Total -le 1) {
        return 'none'
    }

    switch ($Mode) {
        'neutral' {
            if ($Index -eq $Total) { return 'medium' }
            return 'short'
        }
        'dry' {
            if ($Index -eq $Total) { return 'medium' }
            return 'short'
        }
        'sarcastic' {
            if ($Index -eq $Total) { return 'medium' }
            if ($Index -eq 2 -and $Total -ge 3) { return 'none' }
            return 'short'
        }
        'command' {
            if ($Index -eq 1) { return 'short' }
            return 'none'
        }
    }

    return 'short'
}

function Get-ModeDefaultEmphasis {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ($Mode -eq 'sarcastic') {
        if ($Text -match '(?i)\b(have|now|plan|ruin|stop)\b') {
            return 'caps'
        }
    }
    elseif ($Mode -eq 'command') {
        if ($Text -match '(?i)\b(stay|stop|now|task|route|move|go)\b') {
            return 'slight'
        }
    }

    return 'none'
}

function Format-SmartmouthEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    $modeEntries = Get-ModeSpecificSmartmouthEntries -Text $Text -Mode $Mode
    if ($null -ne $modeEntries -and @($modeEntries).Count -gt 0) {
        $formattedModeEntries = @()
        foreach ($modeEntry in @($modeEntries)) {
            $text = Set-SentenceCase -Text (Normalize-SmartmouthText -Text $modeEntry.Text)
            $text = Add-TerminalPunctuation -Text $text -PauseAfter $modeEntry.PauseAfter
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $formattedModeEntries += (New-SmartmouthEntry -Text $text -PauseAfter $modeEntry.PauseAfter -Emphasis $modeEntry.Emphasis)
            }
        }

        return $formattedModeEntries
    }

    $normalized = Normalize-SmartmouthText -Text $Text
    $normalized = Remove-SmartmouthFillers -Text $normalized

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    $segments = @()
    $sentences = @($normalized -split '(?<=[.!?])\s+')
    $sentenceIndex = 0

    foreach ($sentence in $sentences) {
        $trimmedSentence = $sentence.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedSentence)) {
            continue
        }

        foreach ($clause in ($trimmedSentence -split '\s*;\s*')) {
            $trimmedClause = $clause.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmedClause)) {
                continue
            }

            foreach ($chunk in (Split-ChunkedLine -Text $trimmedClause -MaxWords 6)) {
                $sentenceIndex++
                $pause = Get-ModeDefaultPause -Mode $Mode -Index $sentenceIndex -Total $sentences.Count
                $emphasis = Get-ModeDefaultEmphasis -Mode $Mode -Text $chunk
                $spokenText = Set-SentenceCase -Text (Remove-SmartmouthFillers -Text $chunk)
                $spokenText = Add-TerminalPunctuation -Text $spokenText -PauseAfter $pause
                if (-not [string]::IsNullOrWhiteSpace($spokenText)) {
                    $segments += (New-SmartmouthEntry -Text $spokenText -PauseAfter $pause -Emphasis $emphasis)
                }
            }
        }
    }

    if ($Mode -eq 'sarcastic' -and $segments.Count -gt (Get-SarcasticLineCap)) {
        $segments = @($segments | Select-Object -First (Get-SarcasticLineCap))
    }

    return $segments
}

$formattedEntries = Format-SmartmouthEntries -Text $Line -Mode $Mode
foreach ($entry in $formattedEntries) {
    $entry
}
