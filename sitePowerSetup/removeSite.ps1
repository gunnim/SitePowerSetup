function Remove-Site {

    param (
        [switch] $Silent,
        [string] $AppName = $( Read-Host "Web application name" ),
        [string] $AccountName = $AppName,
        [string] $DatabaseName = $AppName
    )

    if (-Not $Silent) {
        Write-Host 'Preparing to remove Managed Service Account' -foreGroundColor green
        Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
        Read-Host
    }

    Remove-MSA -AccountName $AccountName -Silent:$Silent

    if (-Not $Silent) {
        Write-Host 'Preparing to remove SQL login & database' -foreGroundColor green
        Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
        Read-Host
    }

    foreach ($sqlServer in $SqlDatabaseServers) {
        Remove-Database `
            -SqlServer $sqlServer `
            -DatabaseName $DatabaseName `
            -Silent:$Silent
        Remove-SqlLogin `
            -SqlLogin $AccountName `
            -SqlServer $sqlServer `
            -Silent:$Silent
    }

    foreach ($sqlServer in $SqlLoginServers) {
        Remove-SqlLogin `
            -SqlLogin $AccountName `
            -SqlServer $sqlServer `
            -Silent:$Silent
    }

    if (-Not $Silent) {
        Write-Host "Removed SQL data" -foreGroundColor green
    }


    if (-Not $Silent) {
        Write-Host 'Preparing to remove IIS site + AppPool' -foreGroundColor green
        Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
        Read-Host
    }

    Remove-WebAppPoolHelper -AppName $AppName -Silent:$Silent
    Remove-WebSiteHelper -AppName $AppName -Silent:$Silent
}
