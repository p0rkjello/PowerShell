function Test-IsLocalLogin {
    # Returns True if logged on w/ local account.
    ($env:USERDOMAIN).Equals($env:COMPUTERNAME)
}