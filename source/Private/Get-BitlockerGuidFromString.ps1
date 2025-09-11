function Get-BitlockerGuidFromString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )
    $match = [regex]::Match($InputString, '\{([0-9A-Fa-f-]{36})\}')
    if ($match.Success) {
        return $match.Groups[1].Value
    } else {
        return $null
    }
}