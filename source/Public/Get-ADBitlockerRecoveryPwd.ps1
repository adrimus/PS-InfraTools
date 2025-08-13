function Get-ADBitlockerRecoveryPwd {
    <#
    .SYNOPSIS
    Get's recovery password for BitLocker from Active Directory
    
    .DESCRIPTION
    This function retrieves the BitLocker recovery password for a specified computer from Active Directory.
    It queries the Active Directory for the msFVE-RecoveryInformation object associated with the computer
    and returns the msFVE-RecoveryPassword if available.
    .PARAMETER ComputerName
    The name of the computer for which to retrieve the BitLocker recovery password.
    
    .EXAMPLE
    Get-ADBitlockerRecoveryPwd -ComputerName "Computer01"

    .EXAMPLE
    Set an alias for the function
    Set-Alias -Name Get-ADBLK -Value Get-ADBitlockerRecoveryPwd
    
    .NOTES
    General notes
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )
    # Retrieve the distinguished name of the computer object
    $computerDN = (Get-ADComputer -Identity $ComputerName).DistinguishedName

    # Query Active Directory for BitLocker recovery information
    $splatParams = @{
        Filter      = {objectClass -eq 'msFVE-RecoveryInformation'}
        SearchBase  = $computerDN
        Properties  = 'msFVE-RecoveryPassword'
    }
    $recoveryInfo = Get-ADObject @splatParams

    if ($recoveryInfo) {
        # Output the recovery password if found
        $recoveryInfo | Select-Object -Property msFVE-RecoveryPassword
    } else {
        # Inform the user if no recovery information is found
        Write-Host "No BitLocker recovery information found for $ComputerName"
    }
}
