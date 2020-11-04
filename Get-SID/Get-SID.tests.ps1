$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.tests\.', '.'
. "$here\$sut"


Describe -Name "Get-SID Tests" {

    $RegEx = '^S-\d-\d+-(\d+-){1,14}\d+$'

    It "Should throw on invalid user" {
        { Get-SID 'NotAUserAccountXYZ' } | Should -Throw
    }

    context "No parameters (Get-SID)" {

        $LocalUsr = New-Object System.Security.Principal.NTAccount($env:USERNAME)
        $CurrentUser = $LocalUsr.Translate([System.Security.Principal.SecurityIdentifier]).Value

        $SID = Get-SID

        It "Should match SID RegEx pattern" {
            $SID | Should -Match $RegEx
        }

        It "Should be of type string" {
            $SID | Should -BeOfType ([string])
        }

        It "Should match the current user SID: $CurrentUser" {
            $SID | Should -Match $CurrentUser
        }
    }

    context 'With parameters (Get-SID -UserName "$env:username", "$env:username", "$env:username")' {

        $SIDS = Get-SID -UserName "$env:username", "$env:username", "$env:username"

        It "Should match SID RegEx pattern" {
            $SIDS | Should -Match $RegEx
        }

        It "Should be of type string" {
            $SIDS | Should -BeOfType ([string])
        }

        It "Should have count of 3" {
            $SIDS | Should -HaveCount 3
        }
    }
}
