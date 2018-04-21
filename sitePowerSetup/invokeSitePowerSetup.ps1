##############################
#.SYNOPSIS
#Short description
#
#.DESCRIPTION
#Long description
#
#.PARAMETER Silent
# Minimal output
#
#.PARAMETER AppName
# Web application name
#
#.PARAMETER AccountName
# Optional account name, defaults to AppName
#
#.PARAMETER DatabaseName
# Optional database name, defaults to AppName
#
#.PARAMETER Uninstall
# Remove a previous power setup
#
#.EXAMPLE
# Invoke-WebAppSetup MyWebApp
#
#.NOTES
#General notes
##############################
function Invoke-SitePowerSetup {
[Alias("New-Site", "New-App")]

    param (
        [switch] $Silent,
        [string] $AppName = $( Read-Host "Web application name" ),
        [string] $AccountName = $AppName,
        [string] $DatabaseName = $AppName,
        [switch] $Uninstall
    )

    $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop

    Test-IISInstallation
    Test-AdminRights

    if ($Uninstall) {
        return Remove-Site `
            -Silent:$Silent `
            -AppName $AppName `
            -AccountName $AccountName `
            -DatabaseName $DatabaseName
    }

    if (-Not $Silent) {
        Write-Host 'Preparing to install Managed Service Account' -foreGroundColor green
        Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
        Read-Host
    }

    Invoke-MsaSetup `
        -AccountName $AccountName `
        -Silent:$Silent

    if (-Not $Silent) {
        Write-Host 'Preparing to create SQL databases, logins and users' -foreGroundColor green
        Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
        Read-Host
    }

    Invoke-SqlSetup `
        -AccountName $AccountName `
        -DatabaseName $DatabaseName `
        -Silent:$Silent

    if (-Not $Silent) {
        Write-Host 'Preparing to create IIS site + AppPool' -foreGroundColor green
        Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
        Read-Host
    }

    Invoke-IISSetup `
        -AppName $AppName `
        -AccountName $AccountName `
        -Silent:$Silent
}

