$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.tests\.', '.'
. "$here\$sut"


Describe -Name "Get-TimeStamp" {

    context 'No parameters' {

        $TimeStamp = Get-TimeStamp

        it "Should return 14 digits" {
            ($TimeStamp | Measure-Object -Character).Characters | Should -eq 14
        }

        it "Should -BeOfType string" {
            $TimeStamp | Should -BeOfType ([String])
        }

        it "Should -Not -BeOfType DateTime" {
            $TimeStamp | Should -Not -BeOfType ([DateTime])
        }
    }

    context '-iso8601 parameter' {

        $TimeStamp = Get-TimeStamp -iso8601

        it "Should return an ISO 8601 timestamp" {
            $Regex = '^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\\.[0-9]+)?(Z)?$'
            $TimeStamp | Should -Match $Regex
        }
    }
}
