function Get-SerialNumber {
    <#
    .SYNOPSIS
        Get server serial number

    .PARAMETER ComputerName
        Target computer name.

        Default: "$env:COMPUTERNAME"

    .PARAMETER Credential
        Target computer credential.

    .PARAMETER ShowProgress
        Display the progress meter.

        Default: "$false"

    .EXAMPLE
        get-serialnumber.ps1 -ComputerName SERVER1

    .NOTES
        Author:  Andrew Bounds

    .LINK
        https://github.com/p0rkjello/PowerShell
    #>
    #Requires -Version 3
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
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
                        Activity        = 'Collecting Details...'
                        Id              = '1'
                        Status          = $Status
                        PercentComplete = (($Count / $CountTotal) * 100)
                    }

                    Write-Progress @Progress
                }
            }

            try {
                $Splat = @{
                    Class        = 'win32_bios'
                    ComputerName = $Computer
                    ErrorAction  = 'Stop'
                }

                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $Splat.Credential = $Credential
                }

                $Object = Get-WmiObject @Splat

                [pscustomobject]@{
                    ComputerName = $Computer
                    Manufacturer = $Object.Manufacturer
                    SerialNumber = $Object.SerialNumber
                }
            }
            catch {
                $Exception = $_.Exception.Message
                Write-Warning "[$Computer] $Exception"
            }
        }
    }
}
