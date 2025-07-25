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
    # Export GPO report in XML format and parse it
    $path = "C:\Path\To\ChromeGPO.xml"
    Get-GPOReport -Name "Your GPO Name" -ReportType Xml -Path $path
    Get-GPPolicyData -XmlPath $path

    .EXAMPLE
    # Get all enabled policies
    $computerPolicies = Get-GPPolicyData -XmlPath "C:\Path\To\ChromeGPO.xml"
    $computerPolicies | Where-Object State -eq 'Enabled'

    .NOTES
    General notes
    #>
    param (
        [string]$XmlPath
    )

    [xml]$xmlContent = Get-Content -Path $XmlPath

    $gponame = $xmlContent.gpo.Name

    $policies = $xmlContent.gpo.Computer.ExtensionData.Extension.Policy

    $policyObjects = foreach ($policy in $policies) {
        [PSCustomObject]@{
            GPOName  = $gponame
            Name     = $policy.Name
            State    = $policy.State
            Category = $policy.Category
        }
    }

    return $policyObjects
}
