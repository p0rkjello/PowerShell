function Process-RobocopyLogs {
    <#
    .SYNOPSIS
        Parse RoboCopy logs and export to CSV

    .DESCRIPTION
        Parse RoboCopy logs and export to CSV

    .PARAMETER LogPath
        Path to RoboCopy logs.

    .PARAMETER OutFile
        Output CSV file. Report exported to script directory.

        Default value: 'Process-RobocopyLogs_<datetime>.csv'

    .PARAMETER Timeout
        Job timeout value.

        Default value: '300'

    .PARAMETER MaxThreads
        Number of jobs to run

        Default value: '8'

        .NOTES
            Author:  Andrew Bounds

        .LINK
            https://github.com/p0rkjello/PowerShell
        #>
    #requires -version 3
    [CmdletBinding()]
    param(
        [string]
        $LogPath,

        [string]
        $Outfile,

        [ValidateNotNullOrEmpty()]
        [int32]
        $Timeout = 300,

        [ValidateNotNullOrEmpty()]
        [int32]
        $MaxThreads = 8
    )
    begin {
        # Set script directory, name, and path.
        $ScriptCmd = ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName

        # Use script name as the log name for easier identification.
        # If a log parameter is not defined, create one in the script directory.
        if (-not ($PSBoundParameters.ContainsKey('OutFile'))) {
            $DateStamp = ((Get-Date).ToUniversalTime().ToString("yyyyMMdd_hhmm"))
            $Outfile = '{0}_{1}.csv' -f $ScriptCmd, $DateStamp
            $Outfile = Join-Path -Path $PSScriptRoot -ChildPath $Outfile
        }

        $Files = Get-ChildItem -Path $LogPath -Include *.txt, *.log -Recurse
    }
    process {
        $RemoteJob =
        foreach ($File in $Files) {

            # Skip files of 0 length
            if ($File.Length -eq 0) {
                Write-Verbose "$File size is 0 bytes. Skipping..."
                continue
            }

            # Throttle Start-Job to $MaxThreads
            While (@(Get-Job | Where-Object { $_.State -eq "Running" }).Count -ge $MaxThreads) {
                Write-Verbose "Waiting for open thread...($MaxThreads Maximum)"
                Start-Sleep -Seconds 3
            }

            Write-Host "Starting Job $($File)" -ForegroundColor Green

            Start-Job -Name "$($File)" -ScriptBlock {

                Write-Verbose "Processing: $using:File"
                # $File = Resolve-Path -Path $using:File
                $log = Get-Content -Raw -Path "$using:File"

                $StartedRegex = "\s+Started\s\W\s(?<Started>.*)"
                $SourceRegex = "\s+Source\s\W\s(?<Source>.*)"
                $DestRegex = "\s+Dest\s\W\s(?<Dest>.*)"
                $DirsRegex = "\s+Dirs\s+\W\s+(?<Total>\d+)\s+(?<Copied>\d+)\s+(?<Skipped>\d+)\s+(?<Mismatch>\d+)\s+(?<Failed>\d+)\s+(?<Extras>\d+)"
                $FilesRegex = "\s+Files\s+\W\s+(?<Total>\d+)\s+(?<Copied>\d+)\s+(?<Skipped>\d+)\s+(?<Mismatch>\d+)\s+(?<Failed>\d+)\s+(?<Extras>\d+)"
                # $BytesRegex = "\s+Bytes\s+:\s+" # TODO: Regex
                $TimesRegex = "\s+Times\s+\W\s+(?<Total>\S+)"
                $EndedRegex = "\s+Ended\s\W\s(?<Ended>.*)"

                switch -Regex ($log) {
                    $StartedRegex { $Started = $Matches }
                    $SourceRegex { $Source = $Matches }
                    $DestRegex { $Dest = $Matches }
                    $FilesRegex { $Files = $Matches }
                    $DirsRegex { $Dirs = $Matches }
                    # $BytesRegex { $Bytes = $Matches } # TODO: Regex
                    $TimesRegex { $Times = $Matches }
                    $EndedRegex { $Ended = $Matches }
                }

                function Test-IsHash ($Variable, $Key) {
                    if ($Variable -is [hashtable]) {
                        $Variable["$Key"].Trim()
                    }
                    else {
                        Write-Verbose "$Variable not found."
                        'Not Found!'
                    }
                }

                [pscustomobject]@{
                    File        = $using:File.Name
                    Started     = (Test-IsHash $Started "Started")
                    Ended       = (Test-IsHash $Ended "Ended")
                    Source      = (Test-IsHash $Source "Source")
                    Dest        = (Test-IsHash $Dest "Dest")
                    DirsTotal   = (Test-IsHash $Dirs "Total")
                    DirsCopied  = (Test-IsHash $Dirs "Copied")
                    DirsFailed  = (Test-IsHash $Dirs "Failed")
                    FilesTotal  = (Test-IsHash $Files "Total")
                    FilesCopied = (Test-IsHash $Files "Copied")
                    FilesFailed = (Test-IsHash $Files "Failed")
                    # BytesTotal  = $Bytes["Total"].Trim() TODO: Regex
                    # BytesCopied = $Bytes["Copied"].Trim() TODO: Regex
                    # BytesFailed = $Bytes["Failed"].Trim() TODO: Regex
                    TimesTotal  = (Test-IsHash $Times "Total")
                }
            }
        }
        $RemoteJob | Wait-Job -Timeout $Timeout | Out-Null
    }
    end {
        $Jobs = Get-Job
        $Results = $Jobs | Receive-Job
        Get-Job | Remove-Job
        if ($Results) {
            $Results
            if ($OutFile) {
                $Results | Export-Csv $OutFile -NoTypeInformation -NoClobber
                if ((Test-Path -Path $OutFile -PathType Leaf)) {
                    Write-Host "Output saved to `"$OutFile`"" -ForegroundColor Green
                    Write-Host `n
                }
            }
        }
    }
}
