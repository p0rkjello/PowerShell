function Get-TimeStamp {
    <#
    .SYNOPSIS
        Get time stamp
    .NOTES
        Author:  Andrew Bounds
    .LINK
        https://github.com/p0rkjello/PowerShell
    #>
    param (
        # Return an UTC ISO 8601 timestamp (ie: "2020-06-16T17:33:27Z")
        [switch]
        $iso8601 = $false
    )
    $String = switch ($iso8601.IsPresent) {
        true { 'yyyy-MM-ddTHH:mm:ssZ' }
        false { 'yyyyMMddHHmmss' }
    }
    (Get-Date).ToUniversalTime().ToString($String)
}
