function New-WebAppPoolHelper {
    [CmdletBinding()]
    Param (
        [string] $AppName,
        [string] $AccountName,
        [switch] $Quiet
    )

    try {
        $result = New-WebAppPool $AppName

        # no null errors in whatif mode
        Write-Verbose !$result
    }
    catch {
        if (($_.Exception.PSObject.Properties.name -match 'ErrorCode' -and 
                $_.Exception.ErrorCode -eq -2147024713) -or 
            $_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::InvalidArgument) {
            if (-Not $Quiet) {
                Write-Warning "ApplicationPool with name $AppName already exists"
            }
        }
        else {
            throw $_
        }
    }

    # Set AppPool Identity
    if ($WhatIfPreference) {
        Write-Output "What if: Would Set-ItemProperty 'processModel' on IIS:\AppPools\$AppName to value " + 
        "@{userName = '$Env:USERDOMAIN\$AccountName$'; password = ''; identitytype = 3}"
    }
    else {
        Set-ItemProperty IIS:\AppPools\$AppName `
            -name processModel `
            -value @{
            userName     = "$Env:USERDOMAIN\$AccountName$"
            password     = ""
            identitytype = 3
        }
    }
}

function New-WebSiteHelper {
    Param (
        [string] $AppName,
        [string] $PhysicalPath,
        [string] $Binding,
        [switch] $Quiet
    )

    try {
        $Binding = Format-Binding $Binding $AppName

        $result = New-Website $AppName `
            -PhysicalPath $PhysicalPath `
            -ApplicationPool $AppName `
            -HostHeader $Binding `
            -Force

        Write-Verbose !$result
    }
    catch {
        if (($_.Exception.PSObject.Properties.name -match 'ErrorCode' -and 
            $_.Exception.ErrorCode -eq -2147024713) -or 
            $_.Exception.HResult -eq -2147024809) {
            if (-Not $Quiet) {
                Write-Warning "IIS site with name $AppName already exists"
            }
        }
        else {
            throw $_
        }
    }
}
