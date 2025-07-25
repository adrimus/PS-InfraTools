#Requires -Modules GroupPolicy
#Requires -Version 3.0
#Requires -RunAsAdministrator

function Get-GPOLinks {
    <#
    .SYNOPSIS
        Gets all OU locations where a specified GPO is linked.
    
    .DESCRIPTION
        This function finds all organizational units (OUs) where a specified Group Policy Object (GPO) is linked.
        It returns custom objects containing the GPO and OU details for each link found.
    
    .PARAMETER GPOName
        The name of the Group Policy Object to search for.
    
    .EXAMPLE
        Get-GPOLinks -GPOName "Default Domain Policy"
        Returns all OUs where the "Default Domain Policy" GPO is linked.
    
    .EXAMPLE
        Get-GPOLinks -GPOName "Security Settings" | Remove-GPOLinks -WhatIf
        Shows what links would be removed without actually removing them.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GPOName
    )

    try {
        $gpo = Get-GPO -Name $GPOName -ErrorAction Stop
        $allOUs = Get-ADOrganizationalUnit -Filter * -Properties DistinguishedName

        foreach ($ou in $allOUs) {
            $links = Get-GPInheritance -Target $ou.DistinguishedName
            
            if ($links.GpoLinks.DisplayName -contains $GPOName) {
                [PSCustomObject]@{
                    GPOName = $GPOName
                    OUName = $ou.Name
                    OUPath = $ou.DistinguishedName
                    GPOID = $gpo.Id
                }
            }
        }
    }
    catch {
        Write-Error "Error occurred:: $_"
    }
}

function Remove-GPOLinks {
    <#
    .SYNOPSIS
        Removes GPO links from specified organizational units.
    
    .DESCRIPTION
        This function removes Group Policy Object (GPO) links from organizational units (OUs).
        It supports pipeline input from Get-GPOLinks and includes WhatIf/Confirm support.
    
    .PARAMETER OUPath
        The distinguished name of the OU from which to remove the GPO link.
    
    .PARAMETER GPOName
        The name of the GPO to unlink.
    
    .EXAMPLE
        Get-GPOLinks -GPOName "Security Settings" | Remove-GPOLinks
        Finds all links for the "Security Settings" GPO and removes them with confirmation.
    
    .EXAMPLE
        Get-GPOLinks -GPOName "Default Domain Policy" | Remove-GPOLinks -Confirm:$false
        Removes all links for the specified GPO without prompting for confirmation.
    
    .EXAMPLE
        Get-GPOLinks -GPOName "Remote Access" | Remove-GPOLinks -WhatIf
        Shows what GPO links would be removed without actually removing them.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$OUPath,
        
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$GPOName
    )
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("$GPOName from $OUPath", "Remove GPO Link")) {
                Remove-GPLink -Name $GPOName -Target $OUPath -ErrorAction Stop
                Write-Host "Successfully removed GPO link '$GPOName' from '$OUPath'" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Failed to remove GPO link from $OUPath $_"
        }
    }
}

function Add-GPOLinks {
    <#
    .SYNOPSIS
        Adds GPO links to specified organizational units.
    
    .DESCRIPTION
        This function adds Group Policy Object (GPO) links to organizational units (OUs).
        It supports pipeline input and includes WhatIf/Confirm support.
    
    .PARAMETER OUPath
        The distinguished name of the OU to which to add the GPO link.
    
    .PARAMETER GPOName
        The name of the GPO to link.
    
    .EXAMPLE
        [PSCustomObject]@{
            GPOName = "Security Settings"
            OUPath = "OU=Sales,DC=contoso,DC=com"
        } | Add-GPOLinks
        Adds the specified GPO link to the Sales OU.
    
    .EXAMPLE
        Get-GPOLinks -GPOName "Security Settings" | Add-GPOLinks -WhatIf
        Shows what links would be added without actually adding them.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$OUPath,
        
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$GPOName
    )
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("$GPOName to $OUPath", "Add GPO Link")) {
                New-GPLink -Name $GPOName -Target $OUPath -ErrorAction Stop
                Write-Host "Successfully added GPO link '$GPOName' to '$OUPath'" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "Failed to add GPO link to $OUPath:: $_"
        }
    }
}
