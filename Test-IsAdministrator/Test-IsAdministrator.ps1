function Test-IsAdministrator {
    $Administrator = [Security.Principal.WindowsBuiltinRole]::Administrator
    $User = [Security.Principal.WindowsIdentity]::GetCurrent();
    ([Security.Principal.WindowsPrincipal]($User)).IsInRole($Administrator)
}