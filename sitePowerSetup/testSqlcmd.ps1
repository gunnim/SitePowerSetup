function Test-Sqlcmd {

    $hasSqlPsTools = 
        Get-Command `
        -Name Invoke-Sqlcmd `
        -ErrorAction SilentlyContinue

    if ($hasSqlPsTools -eq $null) {
        Install-Module SqlServer
    }
}
