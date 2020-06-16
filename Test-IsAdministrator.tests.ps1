$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.tests\.', '.'
. "$here\$sut"


Describe -Name "Test-IsAdministrator" {

    It "Should return boolean" {
        Test-IsAdministrator | Should -BeOfType ([bool])
    }

    Context "Return value" {

        It "Should return true when Administrator" {

            Mock Test-IsAdministrator { return $true }

            Test-IsAdministrator | Should -BeTrue
        }

        It "Should return false when not Administrator" {

            Mock Test-IsAdministrator { return $false }

            Test-IsAdministrator | Should -BeFalse
        }
    }
}