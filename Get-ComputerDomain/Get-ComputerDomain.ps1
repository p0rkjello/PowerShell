function Get-ComputerDomain {
    (Get-WmiObject Win32_ComputerSystem).Domain
}