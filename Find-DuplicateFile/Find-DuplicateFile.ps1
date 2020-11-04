function Find-DuplicateFile {
    <#
    .SYNOPSIS
        Find duplicate files.

    .DESCRIPTION
        Recursively check for duplicate files.

    .PARAMETER Path
        Directory path. Example: 'C:\Users\DataHorder' 

    .PARAMETER Algorithm
        Algorithm to hash file.

        Default: 'SHA1'

    .PARAMETER ZeroLength
        Check for 0 size files.

        Default: "$false"

    .EXAMPLE
        Find-DuplicateFile -Path 'C:\Users\DataHorder'

    .NOTES
        Author:  Andrew Bounds

    .LINK
        https://github.com/p0rkjello/PowerShell
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]
        $Path,

        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string]
        $Algorithm = 'SHA1',

        [switch]
        $ZeroLength = $false
    )
    begin {
        $MinLength = if ($ZeroLength.IsPresent) { 0 } else { 1 }
    }
    process {
        Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -ge $MinLength } | 
                Get-FileHash -Algorithm $Algorithm -ErrorAction SilentlyContinue |
                    Group-Object -Property Hash |
                        Where-Object { $_.Count -gt 1 }
    }
}
