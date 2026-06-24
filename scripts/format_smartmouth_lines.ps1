[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Line,

    [ValidateSet('neutral', 'dry', 'sarcastic', 'command')]
    [string]$Mode = 'neutral'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    $result = $result -replace '\bthat\b(?=\s+(?:now|we|this|there|is|are|was|were|plan|step|move|route|go|means|looks|feels|sounds?|needs?|can|will|should|I|it))', ''
    $result = $result -replace '\bjust\b(?=\s+(?:need|need to|have|need a|need an))', ''
    $result = $result -replace '\s+', ' '
    return $result.Trim()
}

function Add-TerminalPunctuation {
    param([Parameter(Mandatory = $true)][string]$Text)

    $trimmed = $Text.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $null
    }

    if ($trimmed -notmatch '[.!?]$') {
        $trimmed += '.'
    }

    return $trimmed
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

function Get-ModeSpecificSmartmouthLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    $normalized = ($Text -replace '[.!?]+', '.').ToLowerInvariant().Trim()

    if ($normalized -match '^routing now\.?\s*shocking development:\s*we are using a plan\.?$') {
        switch ($Mode) {
            'dry' {
                return @(
                    'Routing now.',
                    'We actually have a plan.'
                )
            }
            'sarcastic' {
                return @(
                    'Routing now.',
                    'We have a plan.',
                    'Try not to ruin it.'
                )
            }
            'command' {
                return @(
                    'Routing now.',
                    'Stay on task.'
                )
            }
            default {
                return @(
                    'Routing now.',
                    'Shocking development.',
                    'We are using a plan.'
                )
            }
        }
    }

    if ($normalized -match '^relay online\.?\s*try not to break anything expensive\.?$') {
        switch ($Mode) {
            'dry' {
                return @(
                    'Relay online.',
                    'Try not to break anything expensive.'
                )
            }
            'sarcastic' {
                return @(
                    'Relay online.',
                    'Try not to break anything expensive.'
                )
            }
            'command' {
                return @(
                    'Relay online.',
                    'Do not break expensive things.'
                )
            }
            default {
                return @(
                    'Relay online.',
                    'Try not to break anything expensive.'
                )
            }
        }
    }

    if ($normalized -match '^i can make this faster, cleaner, and less cursed\.?$') {
        switch ($Mode) {
            'dry' {
                return @(
                    'I can make this faster.',
                    'Cleaner.',
                    'Less cursed.'
                )
            }
            'sarcastic' {
                return @(
                    'I can make this faster.',
                    'Cleaner.',
                    'Less cursed.'
                )
            }
            'command' {
                return @(
                    'Make it faster.',
                    'Keep it clean.',
                    'Keep it less cursed.'
                )
            }
            default {
                return @(
                    'I can make this faster.',
                    'Cleaner.',
                    'Less cursed.'
                )
            }
        }
    }

    return $null
}

function Format-SmartmouthLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    $modeLines = Get-ModeSpecificSmartmouthLines -Text $Text -Mode $Mode
    if ($null -ne $modeLines -and $modeLines.Count -gt 0) {
        return @(
            $modeLines |
                ForEach-Object {
                    Set-SentenceCase -Text (Add-TerminalPunctuation -Text (Normalize-SmartmouthText -Text $_))
                } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    $normalized = Normalize-SmartmouthText -Text $Text
    $normalized = Remove-SmartmouthFillers -Text $normalized

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    $segments = New-Object System.Collections.Generic.List[string]

    foreach ($sentence in ($normalized -split '(?<=[.!?])\s+')) {
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
                $finalLine = Set-SentenceCase -Text (Add-TerminalPunctuation -Text (Remove-SmartmouthFillers -Text $chunk))
                if (-not [string]::IsNullOrWhiteSpace($finalLine)) {
                    [void]$segments.Add($finalLine)
                }
            }
        }
    }

    return @($segments)
}

$formattedLines = Format-SmartmouthLines -Text $Line -Mode $Mode
if ($formattedLines.Count -eq 0) {
    return
}

foreach ($formattedLine in $formattedLines) {
    $formattedLine
}
