function New-SqlSetup {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $AccountName = $( Read-Host "Service account name" ),

        [string] $DatabaseName = $AccountName,
        [switch] $Silent
    )

    $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
    Test-Sqlcmd
    Test-AdminRights

    foreach ($sqlServer in $SqlDatabaseServers) {
        New-Database -SqlServer $sqlServer -DatabaseName $DatabaseName -Silent:$Silent
        New-SqlLogin -SqlLogin $AccountName -SqlServer $sqlServer -Silent:$Silent
        New-SqlUser -SqlUser $AccountName -SqlServer $sqlServer -Database $DatabaseName -Silent:$Silent
        if (-Not $Silent) {
            Write-Host "Ensured sql database, login & user on $sqlServer" -foreGroundColor green
        }
    }

    foreach ($sqlServer in $SqlLoginServers) {
        New-SqlLogin -SqlLogin $AccountName -SqlServer $sqlServer -Silent:$Silent
        if (-Not $Silent) {
            Write-Host "Ensured sql login on $sqlServer" -foreGroundColor green
        }
    }
}
