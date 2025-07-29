function Get-GPPolicyData {
    <#
    .SYNOPSIS
    Parses Chrome Group Policy XML files and extracts policy information.

    .DESCRIPTION
    This function reads a Chrome Group Policy XML file and extracts relevant policy information
    into a structured format for further processing.

    .PARAMETER XmlPath
    Parameter description
    
    .EXAMPLE
    # Get policy data from a GPO by name

    Get-GPPolicyData -GPOName "Your GPO Name"

    .EXAMPLE
    # Get all enabled policies
    $computerPolicies = Get-GPPolicyData -GPOName "Your GPO Name"
    $computerPolicies | Where-Object State -eq 'Enabled'

    .NOTES
    General notes
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GPOName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Computer", "User", "All")]
        [string]$Configuration
    )

    [xml]$xmlContent = Get-GPOReport -Name $GPOName -ReportType Xml
    

    $gponame = $xmlContent.gpo.Name

    $policies = switch ($Configuration) {
        "Computer" {
            $xmlContent.gpo.Computer.ExtensionData.Extension.Policy
        }
        "User" {
            $xmlContent.gpo.User.ExtensionData.Extension.Policy
        }
        "All" {
            # No change needed, we will process both Computer and User policies
            $xmlContent.gpo.Computer.ExtensionData.Extension.Policy + $xmlContent.gpo.User.ExtensionData.Extension.Policy
        }
    }

    # display user or computer from the XML path


    $policyObjects = foreach ($policy in $policies) {
        [PSCustomObject]@{
            Configuration = $policy.ParentNode.ParentNode.ParentNode.Name
            GPOName       = $policy.ParentNode.ParentNode.ParentNode.ParentNode.Name
            Name          = $policy.Name
            State         = $policy.State
            Category      = $policy.Category
        }
    }

    return $policyObjects
}
