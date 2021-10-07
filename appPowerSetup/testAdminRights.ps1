function Test-AdminRights {
    # Check for admin rights
    $curPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [Security.Principal.WindowsBuiltInRole] "Administrator"
    If (-NOT $curPrincipal.IsInRole($adminRole))
    {
        throw "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    }
}
