function Get-SysDriveSpace {
    <#
    .SYNOPSIS
        Report free space on C: drive

    .DESCRIPTION
        Report System drive freespace to identify ComputerName <30%

    .PARAMETER ComputerName
        Target computer name.

        Default: "$env:COMPUTERNAME"

    .PARAMETER Credential
        Target computer credential.

    .PARAMETER ShowProgress
        Display the progress meter.

        Default: "$false"

    .PARAMETER Timeout
        Cim Instance timeout.

        Default: '30'

    .PARAMETER Protocol
        Cim Session protocol. Dcom or Wsman

    .EXAMPLE
        Get-SysDriveSpace.ps1 -ComputerName Computer1

    .NOTES
        Author: Andrew Bounds

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
        $ShowProgress = $false,

        [int]
        $Timeout = 30,

        [ValidateSet('Dcom', 'Wsman')]
        [string]
        $Protocol
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
                        Activity        = 'Collecting Disk Space'
                        Id              = '1'
                        Status          = $Status
                        PercentComplete = (($Count / $CountTotal) * 100)
                    }
                    Write-Progress @Progress
                }
            }

            # Build CimSession
            $CimSessionSplat = @{
                ComputerName = $Computer
            }

            # Build CimSessionOptions
            if ($PSBoundParameters.ContainsKey('Protocol')) {
                $Opt = New-CimSessionOption -Protocol $Protocol
                $CimSessionSplat.SessionOption = $Opt
            }
            else {
                if (-not (Test-WSMan @CimSessionSplat -ErrorAction SilentlyContinue)) {
                    $Opt = New-CimSessionOption -Protocol Dcom
                    $CimSessionSplat.SessionOption = $opt
                }
            }

            if ($PSBoundParameters.ContainsKey('Credential')) {
                $CimSessionSplat.Credential = $Credential
            }

            $CimSessionSplat.ErrorAction = 'Stop'

            try {
                $CS = New-CimSession @CimSessionSplat
            }
            catch {
                $Exception = $_.Exception.Message
                Write-Warning "[$Computer] $Exception"
            }

            # Continue on loop if not able to create a CimSession
            if (-not ($CS)) { continue }

            # Build CimInstance
            $CimInstanceSplat = @{
                ClassName           = "Win32_LogicalDisk"
                Filter              = "DeviceID = 'C:'"
                OperationTimeoutSec = "$Timeout"
                ErrorAction         = "Stop"
            }

            try {
                $DriveInfo = Get-CimInstance @CimInstanceSplat -CimSession $CS
            }
            catch {
                $Exception = $_.exception.message
                Write-Warning "[$Computer] $Exception"
            }

            $DiskSize = [math]::round($DriveInfo.Size / 1GB)
            $DiskFree = [math]::round($DriveInfo.FreeSpace / 1GB)

            if ($DiskSize -eq 0) { $Percent = 0 } else {
                $Percent = ($DiskFree / $DiskSize).ToString("P")
            }

            [pscustomobject]@{
                'Computer'        = $DriveInfo.PSComputerName
                'Drive'           = $DriveInfo.DeviceID
                'Size (GB)'       = $DiskSize
                'FreeSpace (GB)'  = $DiskFree
                'Percentage Free' = $Percent
            }
        }
    }
}
