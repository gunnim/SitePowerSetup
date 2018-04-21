function Invoke-IISSetup {
    param (
        [switch] $Silent,
        [string] $AppName = $( Read-Host "Web Application Name" ),
        [string] $AccountName = $AppName
    )

    $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
    Test-IISInstallation
    Test-AdminRights

    $folder = Get-Folder $Env:USERPROFILE

    if ($folder) {

        try {
            New-WebAppPool $AppName
        }
        catch {
            if ($_.Exception.ErrorCode -eq -2147024713) {
                Write-Warning "ApplicationPool with name $AppName already exists"
            }
            else {
                Write-Host $_ -ForegroundColor Red
                break
            }
        }

        # Set AppPool Identity
        Set-ItemProperty IIS:\AppPools\$AppName `
            -name processModel `
            -value @{userName = "$Env:USERDOMAIN\$AccountName$"; password = ""; identitytype = 3}

        try {
            if ($DefaultBindingSuffix -eq $null) {
                $DefaultBindingSuffix = "localhost.$Env:USERDNSDOMAIN"
            }
            New-Website $AppName `
                -PhysicalPath $folder `
                -ApplicationPool $AppName `
                -HostHeader "$AppName.$DefaultBindingSuffix"
        }
        catch {
            if ($_.Exception.ErrorCode -eq -2147024713) {
                if (-Not $Silent) {
                    Write-Warning "IIS site with name $AppName already exists"
                }
            }
            else {
                throw $_
            }
        }
        
        if (-Not $Silent) {
            Write-Host 'Successfully created IIS site and AppPool' -foreGroundColor green
        }
    }
    else {
        throw 'Error getting target folder for Web App'
    }
}
