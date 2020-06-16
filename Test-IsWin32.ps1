function Test-IsWin32 {
    return [IntPtr]::size -eq 4
}
