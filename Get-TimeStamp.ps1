function Get-TimeStamp {
    param (
        # Return an UTC ISO 8601 timestamp (ie: "2020-06-16T17:33:27Z")
        [switch]
        $iso8601 = $false
    )
    $String = switch ($iso8601) {
        true { 'yyyy-MM-ddTHH:mm:ssZ' }
        false { 'yyyyMMddHHmmss' }
    }
    (Get-Date).ToUniversalTime().ToString($String)
}