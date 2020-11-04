function Get-FreeSpace {
    <#
    .SYNOPSIS
        Report free space.

    .DESCRIPTION
        Report per drive disk space totals and percentage free.

    .PARAMETER ComputerName
        Target computer name.

        Default: "$env:COMPUTERNAME"

    .PARAMETER Credential
        Target computer credential.

    .PARAMETER ShowProgress
        Display the progress meter.

        Default: "$false"

    .EXAMPLE
        Get-FreeSpace.ps1 -ComputerName SERVER1

    .NOTES
        Author:  Andrew Bounds

    .LINK
        https://github.com/p0rkjello/PowerShell
    #>
    #Requires -Version 3
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Alias("RunAs")]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [switch]
        $ShowProgress = $false
    )

    begin {
        $Computer = $null
        [int]$CountTotal = $ComputerName.Count
        [int]$Count = 0
    }
    process {
        foreach ($Computer in $ComputerName) {

            $Computer = $Computer.ToLower()

            if ($ShowProgress.IsPresent) {
                if ($CountTotal -gt 0) {

                    $Count++
                    $Status = '{0} / {1} | {2}' -f $Count, $CountTotal, $Computer

                    $Progress = @{
                        Activity        = 'Collecting Disk Usage'
                        Id              = '1'
                        Status          = $Status
                        PercentComplete = (($Count / $CountTotal) * 100)
                    }
                    Write-Progress @Progress
                }
            }

            try {
                $Splat = @{
                    Class        = "Win32_LogicalDisk"
                    ComputerName = "$Computer"
                    filter       = "DriveType = 3"
                    ErrorAction  = "Stop"
                }

                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $Splat.Credential = $Credential
                }

                $Object = Get-WmiObject @Splat

                $Object | ForEach-Object {
                    [PSCustomObject]@{
                        'Computer Name'       = $Computer
                        'Drive Letter'        = $_.DeviceID
                        'Total Capacity (GB)' = $([math]::Round($_.Size / 1GB, 2))
                        'Free Space (GB)'     = $([math]::Round($_.Freespace / 1GB, 2))
                        'Percentage Free (%)' = $("{0:P0}" -f ($_.Freespace / $_.Size))
                    }
                }
            }
            catch {
                $Exception = $_.Exception.Message
                Write-Warning "[$Computer] $Exception"
                continue
            }
        }
    }
}