function Get-ProfileSize {
    <#
    .SYNOPSIS
        Generate a list of profile sizes.

    .DESCRIPTION
        List user profile size, location, and special status (Loaded, Special)

    .PARAMETER ComputerName
        Computer name to run script

    .PARAMETER ShowProgress
        Display the progress meter.

        Default: "$false"

    .NOTES
        Author:  Andrew Bounds

    .LINK
        https://github.com/p0rkjello/PowerShell
    #>
    #requires -version 3
    [cmdletbinding()]
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
        function Get-DirSize($Path) {
            $GCISplat = @{
                Path = $Path
                Recurse = $true
                Force = $true
                ErrorAction = 'SilentlyContinue'
            }
            [math]::Round((Get-Childitem @GCISplat | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB, 2)
        }
    }
    process {
        # Initialize Server Progress
        [int]$CountTotal = $($ComputerName).Count
        [int]$Count = 0

        foreach ($Computer in $ComputerName) {

            $Computer = $Computer.ToLower()

            if ($ShowProgress.IsPresent) {
                if ($CountTotal -gt 0) {
                    $Count++
                    $Progress = @{
                        Activity        = "Collecting Server Info ..."
                        Id              = "1"
                        # ParentId      = "1"
                        Status          = "Searching:  $Computer" # "Running $CountGroup / $CountTotalGroup"
                        PercentComplete = (($Count / $CountTotal) * 100)
                    }

                    Write-Progress @Progress
                }
            }

            if ($Computer -ne $env:COMPUTERNAME) {
                if (-not (Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                    Write-Warning -Message "Unable to connect to $Computer"
                    continue
                }
            }
            try {
                $SessionSplat = @{
                    ComputerName = "$Computer"
                    ErrorAction  = "Stop"
                }
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $SessionSplat.Credential = $Credential
                }

                $InstanceSplat = @{
                    Class = "Win32_UserProfile"
                }
                # Using WMI, import the user profile list into the $UserProfile variable
                $Session = New-CimSession @SessionSplat
                $UserProfile = Get-CimInstance @InstanceSplat -CimSession $Session

                # Initialize Profile Progress
                [int]$ProfileCountTotal = $($UserProfile.Count)
                [int]$ProfileCount = 0

                foreach ($Profile in $UserProfile) {

                    try {
                        $objSID = New-Object System.Security.Principal.SecurityIdentifier($Profile.sid)
                        $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
                        $objUsername = $objUser.value
                    }
                    catch {
                        $objUsername = $Profile.sid
                    }

                    if ($ShowProgress.IsPresent) {
                        if ($ProfileCountTotal -gt 0) {
                            $ProfileCount++
                            $ProfileProgress = @{
                                Activity        = "Collecting Profile details ..."
                                Id              = "2"
                                ParentId        = "1"
                                Status          = "Searching:  $objUsername"
                                PercentComplete = (($ProfileCount / $ProfileCountTotal) * 100)
                            }

                            Write-Progress @ProfileProgress
                        }
                    }

                    $SizeMB = (Get-Dirsize $Profile.LocalPath)

                    [PSCustomObject]@{
                        Name        = $objUsername
                        LocalPath   = $Profile.LocalPath
                        Special     = $Profile.Special
                        Loaded      = $Profile.Loaded
                        LastUseTime = $Profile.LastUseTime
                        SizeMB      = $SizeMB
                    }
                }
            }
            catch {
                $Exception = $_.Exception.Message
                Write-Error $Exception
            }
        }
    }
    end {
        Remove-CimSession -CimSession $Session
    }
}