function Find-DuplicateFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]
        $Path,

        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string]
        $Algorithm = 'MD5'
    )
    process {
        $Path | Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue |
            Get-FileHash -Algorithm $Algorithm -ErrorAction SilentlyContinue|
                Group-Object -Property Hash |
                    Where-Object { $_.Count -gt 1 }
    }
}
