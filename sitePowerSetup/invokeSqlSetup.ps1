function Invoke-SqlSetup {
    param (
        [switch] $Silent,
        [string] $AccountName = $( Read-Host "Service account name" ),
        [string] $DatabaseName = $AccountName
    )

    $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
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
