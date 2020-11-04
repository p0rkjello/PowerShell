function Get-UsedSpace {
    <#
    .SYNOPSIS
        Report disk space

    .DESCRIPTION
        Report disk capacity and total usage

    .PARAMETER ComputerName
        Target computer name.

        Default: "$env:COMPUTERNAME"

    .PARAMETER Credential
        Target computer credential.

    .PARAMETER ShowProgress
        Display the progress meter.

        Default: "$false"

    .EXAMPLE
        Get-UsedSpace.ps1 -ComputerName Computer1, Computer2

        List space using Computer names

    .NOTES
        Author:  Andrew Bounds

    .LINK
        https://github.com/p0rkjello/PowerShell
    #>
    #Requires -Version 3
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
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
                        Activity        = 'Collecting Information...'
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
                    $splat.Credential = $Credential
                }

                $Object = Get-WmiObject @Splat
            }
            catch {
                $Exception = $_.Exception.Message
                Write-Warning "[$Computer] $Exception"
                continue
            }

            $DiskTotal      = (($Object.Size | Measure-Object -Sum).Sum)
            $FreespaceTotal = (($Object.Freespace | Measure-Object -Sum).Sum)
            $UsedspaceTotal = ($DiskTotal - $FreespaceTotal)

            [pscustomobject]@{
                'Computer Name'       = $Computer
                'Total Capacity (GB)' = $([math]::Round($DiskTotal / 1GB, 2))
                'Free Space (GB)'     = $([math]::Round($FreespaceTotal / 1GB, 2))
                'Total Usage (GB)'    = $([math]::Round($UsedspaceTotal / 1GB, 2))
            }
        }
    }
}