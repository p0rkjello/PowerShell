function Test-IsWorkgroup {
    (-not(Get-WmiObject -Class win32_ComputerSystem).PartOfDomain)
}
