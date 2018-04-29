function New-WebAppPoolHelper {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [string] $AppName,
        [string] $AccountName,
        [switch] $Quiet
    )

    try {
        $result = New-WebAppPool $AppName

        # no null errors in whatif mode
        if ($result -ne $null) {
            Write-Verbose $result
        }
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
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [string] $AppName,
        [string] $PhysicalPath,
        [string] $Binding,
        [switch] $Quiet
    )

    try {
        $Binding = Format-Binding $Binding $AppName

        # Since we need the -Force parameter to be able to
        # create a site with an empty physicalPath
        # We must ensure we are not overwriting a previously created site
        if ((Get-Website $AppName) -eq $null) {
            $result = New-Website $AppName `
            -PhysicalPath $PhysicalPath `
            -ApplicationPool $AppName `
            -HostHeader $Binding `
            -Force

            # no null errors in whatif mode
            if ($result -ne $null) {
                Write-Verbose $result
            }
        }
        elseIf (-Not $Quiet) {
            Write-Warning "IIS site with name $AppName already exists"
        }
    }
    catch {

        # The following block is rendered useless because
        # we use the force parameter, therefore never hitting duplicate errors
        # if (($_.Exception.PSObject.Properties.name -match 'ErrorCode' -and 
        #     $_.Exception.ErrorCode -eq -2147024713) -or 
        #     $_.Exception.HResult -eq -2147024809) {
        #     if (-Not $Quiet) {
        #         Write-Warning "IIS site with name $AppName already exists"
        #     }
        # }
        # else {
            throw $_
        # }
    }
}
