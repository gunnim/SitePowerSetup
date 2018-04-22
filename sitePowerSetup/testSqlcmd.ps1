function Test-Sqlcmd {

    $hasSqlPsTools = 
        Get-Command `
        -Name Invoke-Sqlcmd `
        -ErrorAction SilentlyContinue

    if ($hasSqlPsTools -eq $null) {
        throw 'Sql PowerShell commands missing, please Install-Module SqlServer'
    }
}
