function Remove-UsersExcept {
    <# 
    .DESCRIPTION
        Request to remove all group members except $users_to_keep

    .PARAMETER users_to_keep
        User(s) that will not be removed.

        Note: Use SamAccountName

    .PARAMETER Groups
        Array of groups to process.

    .PARAMETER Delete
        Process the deletion of users from groups.

        Default: "$false"
    #>
    #Requires -Version 3
    [CmdletBinding()]
    Param(
        # Use SamAccountName
        [ValidateNotNullOrEmpty()]
        [string[]]
        $users_to_keep,

        [ValidateNotNullOrEmpty()]
        [string[]]
        $Groups,

        [switch]
        $Delete = $false
    )
    begin {
        # Splat cmdlets for verbose/debug output.
        $CmdletOutput = @{
            Verbose = if ($PSBoundParameters.Verbose) { $true } else { $false }
            Debug   = if ($PSBoundParameters.Debug) { $true } else { $false }
        }
    }
    process {
        foreach ($Group in $Groups) {
            # produce a list of all users excluding $users_to_keep
            $users_to_remove = Get-ADGroupMember $Group |
                Where-Object { $users_to_keep -notcontains $_.SamAccountName }

            if ($users_to_remove) {
                $users_to_remove | ForEach-Object {
                    [pscustomobject]@{
                        "Group" = $Group
                        "Users To Remove" = $_
                    }
                }
            }

            if ($Delete.IsPresent) {
                Remove-ADGroupMember -Identity $Group -Members $users_to_remove @CmdletOutput
            }
        }
    }
}
