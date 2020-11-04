function Get-Sid {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $UserName = "$env:USERNAME"
    )
    process {
        foreach ($Name in $UserName) {
            try {
                $NTAccount = New-Object System.Security.Principal.NTAccount($Name)
                $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}