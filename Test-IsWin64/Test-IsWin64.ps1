function Test-IsWin64 {
    return [IntPtr]::size -eq 8
}