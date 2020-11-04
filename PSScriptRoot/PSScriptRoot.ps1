# $PSScriptRoot for PS 2.0 
if (-not $PSScriptRoot) { 
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
