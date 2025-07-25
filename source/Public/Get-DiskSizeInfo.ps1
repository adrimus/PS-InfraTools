function Get-DiskSizeInfo {
    <#
    .SYNOPSIS
        Get's disk space information
    .DESCRIPTION
        It gets the size of different disk, the free space in GB and the percentage of free space
    .NOTES
        It excludes CD/DVD drives
        I expanded on the script created by Josh Duffney
    .EXAMPLE
        Get-DiskSizeInfo -ComputerName server1
        Get's information from each disk on server 1.
    .EXAMPLE
        Get-DiskSizeInfo -ComputerName "PC001", "PC002" | Format-Table
        Get disk info from two computers and outputs a table.
    .EXAMPLE
        Get-ADComputer -Filter {name -like 'PC*'}| Select-Object -Property @{l='ComputerName';e={$_.name}}  | Get-DiskSizeInfo
        Get's computerobjects from Active Directory and creates a custom property which can be piped into Get-DiskSizeInfo.
    .EXAMPLE
        Get-Content -Path C:\temp\compters.txt | Get-DiskSizeInfo | Sort-Object -Property freespace% | Format-Table
        Get's disk size info from a list in a text file and sorts the output by free space.
    .LINK
    Get-CimInstance
    .LINK
    https://community.spiceworks.com/scripts/show/2106-simple-disk-space-report
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [string[]]
        $ComputerName 
    )
    
    begin {
        
    }
    
    process {
        foreach ($computer in $ComputerName) {
            $params = @{
                ComputerName = $computer
                Classname    = "win32_logicaldisk"
            }
            $drives = Get-CimInstance @params

            foreach ($disk in $drives) {

                if ($disk.Drivetype -ne 5) {

                    [PSCustomObject]@{
                        ComputerName    = $computer
                        Letter          = $disk.DeviceID
                        DriveType       = $disk.drivetype
                        'size(GB)'      = "{0:N1}" -f ($disk.size / 1gb)
                        'FreeSpace(GB)' = "{0:N1}" -f ($disk.freespace / 1gb)
                        'FreeSpace%'    = "{0:P0}" -f ($disk.freespace / $disk.size)
                        VolumeName      = $disk.VolumeName
                    } #Exludes CD drives

                } #if
      
            } #foreach drive

        } #foreach computer

    } #process
    
} #function Get-DiskSizeInfo