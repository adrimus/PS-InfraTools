function Get-GPPolicyData {
    <#
    .SYNOPSIS
    Parses Group Policy XML files and extracts policy information.

    .DESCRIPTION
    This function retrieves policy data from a specified Group Policy Object (GPO) by name. It can filter policies based on configuration type (Computer, User, or All). The function returns a collection of policy objects containing relevant details.

    .PARAMETER GPOName
    The name of the Group Policy Object from which to retrieve policy data.

    .PARAMETER Configuration
    Specifies the type of policies to retrieve. Valid values are "Computer", "User", or "All". If "All" is specified, both Computer and User policies will be returned.
    
    .EXAMPLE
    # Get policy data from a GPO by name

    Get-GPPolicyData -GPOName "Your GPO Name"

    .EXAMPLE
    # Get all enabled policies
    $computerPolicies = Get-GPPolicyData -GPOName "Your GPO Name"
    $computerPolicies | Where-Object State -eq 'Enabled'

    .EXAMPLE
    # Compare two GPOs
    $gpo1Policies = Get-GPPolicyData -GPOName "GPO1"
    $gpo2Policies = Get-GPPolicyData -GPOName "GPO2"
    Compare-Object -ReferenceObject $gpo1Policies -DifferenceObject $gpo2Policies -Property Name, State, Category

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
