function New-IISSetup {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $AppName = $( Read-Host "Web application name" ),
        
        [string] $AccountName = $AppName,
        [switch] $Silent
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
            if (($_.Exception.PSObject.Properties.name -match 'ErrorCode' `
            -and $_.Exception.ErrorCode -eq -2147024713) `
            `
            -or $_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::InvalidArgument) {
                if (-Not $Silent) {
                    Write-Warning "ApplicationPool with name $AppName already exists"
                }
            }
            else {
                throw $_
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
            if (($_.Exception.PSObject.Properties.name -match 'ErrorCode' `
            -and $_.Exception.ErrorCode -eq -2147024713) `
            `
            -or $_.Exception.HResult -eq -2147024809) {
                if (-Not $Silent) {
                    Write-Warning "IIS site with name $AppName already exists"
                }
            }
            else {
                throw $_
            }
        }
        
        if (-Not $Silent) {
            Write-Host 'Successfully ensured IIS site and AppPool' -foreGroundColor green
        }
    }
    else {
        throw 'Error getting target folder for Web App'
    }
}
