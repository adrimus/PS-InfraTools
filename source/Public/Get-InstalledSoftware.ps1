function Get-InstalledSoftware {
    <#
	.SYNOPSIS
		Retrieves a list of all software installed on a Windows computer.
	.EXAMPLE
		PS> Get-InstalledSoftware
		
		This example retrieves all software installed on the local computer.
    .EXAMPLE
        PS> Get-InstalledSoftware -ComputerName PC0001 | Export-Csv c:\temp\kevin.csv -NoTypeInformation

        This example retrieves all software installed on the remote computer and exports them to a csv file which you can open in Excel
	.PARAMETER ComputerName
		If querying a remote computer, use the computer name here.
	
	.PARAMETER Name
		The software title you'd like to limit the query to.
	
	.PARAMETER Guid
		The software GUID you'e like to limit the query to
	#>
    [CmdletBinding()]
    param (
		
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,
		
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
		
        [Parameter()]
        [guid]$Guid
    )
    process {
        foreach ($Computer in $ComputerName) {
            try {
                $scriptBlock = {
                    $args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }
				
                    $UninstallKeys = @(
                        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
                        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                    )
                    New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null
                    $UninstallKeys += Get-ChildItem HKU: | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | foreach {
                        "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall"
                    }
                    if (-not $UninstallKeys) {
                        Write-Warning -Message 'No software registry keys found'
                    }
                    else {
                        foreach ($UninstallKey in $UninstallKeys) {
                            $friendlyNames = @{
                                'DisplayName'    = 'Name'
                                'DisplayVersion' = 'Version'
                            }
                            Write-Verbose -Message "Checking uninstall key [$($UninstallKey)]"
                            if ($Name) {
                                $WhereBlock = { $_.GetValue('DisplayName') -like "$Name*" }
                            }
                            elseif ($GUID) {
                                $WhereBlock = { $_.PsChildName -eq $Guid.Guid }
                            }
                            else {
                                $WhereBlock = { $_.GetValue('DisplayName') }
                            }
                            $SwKeys = Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | Where-Object $WhereBlock
                            if (-not $SwKeys) {
                                Write-Verbose -Message "No software keys in uninstall key $UninstallKey"
                            }
                            else {
                                foreach ($SwKey in $SwKeys) {
                                    $output = @{ }
                                    foreach ($ValName in $SwKey.GetValueNames()) {
                                        if ($ValName -ne 'Version') {
                                            $output.InstallLocation = ''
                                            if ($ValName -eq 'InstallLocation' -and 
                                                ($SwKey.GetValue($ValName)) -and 
                                                (@('C:', 'C:\Windows', 'C:\Windows\System32', 'C:\Windows\SysWOW64') -notcontains $SwKey.GetValue($ValName).TrimEnd('\'))) {
                                                $output.InstallLocation = $SwKey.GetValue($ValName).TrimEnd('\')
                                            }
                                            [string]$ValData = $SwKey.GetValue($ValName)
                                            if ($friendlyNames[$ValName]) {
                                                $output[$friendlyNames[$ValName]] = $ValData.Trim() ## Some registry values have trailing spaces.
                                            }
                                            else {
                                                $output[$ValName] = $ValData.Trim() ## Some registry values trailing spaces
                                            }
                                        }
                                    }
                                    $output.GUID = ''
                                    if ($SwKey.PSChildName -match '\b[A-F0-9]{8}(?:-[A-F0-9]{4}){3}-[A-F0-9]{12}\b') {
                                        $output.GUID = $SwKey.PSChildName
                                    } #if
                                    New-Object -TypeName PSObject -Prop $output
                                } #foreach
                            } #if/else
                        } #foreach
                    } #if/else
                } #scriptblock
			
                if ($Computer -eq $env:COMPUTERNAME) {
                    & $scriptBlock $PSBoundParameters
                }
                else {
                    $softwareinfo = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock -ArgumentList $PSBoundParameters

                    Write-Debug "[PROCESS] on $softwareinfo"

                    $params = @{
                        Identity = $Computer
                        properties = "description"
                        ErrorAction = 'SilentlyContinue'
                    }
                    $Computer = Get-ADComputer @params
                    Write-Debug "[PROCESS] Get AD computer complete"

                    $softwareinfo | Add-Member -MemberType NoteProperty -Name description -Value $Computer.description
                    Write-Debug "[PROCESS] Added description to softwareinfo object"

                    Write-Output $softwareinfo
                } #if/else
            }
            catch {
                Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
            } #try/catch
        } #foreach
    } #process
} #function