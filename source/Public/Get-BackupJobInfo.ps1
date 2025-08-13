function Get-BackupJobInfo {
    <#
    .SYNOPSIS
    Retrieves backup job information from specified servers.
    
    .DESCRIPTION
    Retrieves backup job information from specified servers, including job state, start time, end time, and next run time of the scheduled task. It handles errors by logging them to a CSV file.

    Uses the Get-WBJob cmdlet to get the job state and the Get-ScheduledTask cmdlet to retrieve the next run time of the backup task.
    
    .PARAMETER Computername
    The name of the computer to retrieve backup job information from.

    .EXAMPLE
    Get list of servers and passes list to function using parameter

    $servers = get-content -Path $path 

    # Call the function with the list of servers
    Get-BackupJobInfo -Computername $servers

    .EXAMPLE
    Gets list of servers from a file and retrieves backup job information for each server.
    
    $servers = get-content -Path $path 

    $servers | Get-BackupJobInfo

    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $Computername, 

        $ConnectionErrorsLog = "C:\temp\ConnectionErrors.csv"
    )
    
    begin {
        
    }
    
    process {
        $Computername | ForEach-Object -Parallel {
            $server = $_
            try {
                Write-Verbose "Getting job state for [$server]"
                $WBJob = Invoke-Command -ComputerName $server -ScriptBlock { Get-WBJob -Previous 1 } | Select-Object -Property PSComputerName, jobstate, StartTime, EndTime
    
                $nextRunTime = Invoke-Command -ComputerName $server -ScriptBlock { Get-ScheduledTask -TaskName Microsoft-Windows-WindowsBackup | Get-ScheduledTaskInfo | select-object -ExpandProperty NextRunTime }

                Write-Verbose "Getting Backup Scheduled task trigger for [$server]"
                $trigger = Invoke-Command -ComputerName $server -ScriptBlock { Get-ScheduledTask -TaskName Microsoft-Windows-WindowsBackup | Select-Object -ExpandProperty triggers }
                
                Write-Verbose "$trigger"
                if ($trigger.WeeksInterval) {
                    
                }
                elseif ($trigger.DaysInterval) {
                    <# Action when this condition is true #>
                } # else if
    
                Write-Verbose "Output object for [$server]"
                [PSCustomObject]@{
                    ComputerName = $server
                    jobstate     = $WBJob.jobstate
                    StartTime    = $WBJob.StartTime
                    EndTime      = $WBJob.EndTime
                    nextRunTime  = $nextRunTime
                }
            }
            catch {
                # Add any errors to the connection error CSV file
                [pscustomobject]@{
                    ComputerName = $server
                    Date         = Get-Date
                    ErrorMsg     = $_
                } | Export-Csv -Path $ConnectionErrors -Append
            } # try/catch
        }
    }
    
    end {
        
    }
} # function