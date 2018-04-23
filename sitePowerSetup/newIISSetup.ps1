function New-IISSetup {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName = $( Read-Host "Web application name" ),
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $AccountName = $AppName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("Path", "Directory", "Folder")]
        [string]
        $PhysicalPath,

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
            [System.Management.Automation.ActionPreference]::Stop
        Test-IISInstallation
        Test-AdminRights
    }

    Process {
        if ([string]::IsNullOrEmpty($null)) {
            $PhysicalPath = Get-Folder $Env:USERPROFILE
        }
        elseIf (-Not (Test-Path $PhysicalPath)) {
            Write-Warning 'Invalid path supplied'
            $PhysicalPath = Get-Folder $Env:USERPROFILE
        }

        if ($PhysicalPath) {
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
                    -value @{userName = "$Env:USERDOMAIN\$AccountName$"; password = ""; identitytype = 3}
            }
    
            try {
                if ($DefaultBindingSuffix -eq $null) {
                    $DefaultBindingSuffix = "localhost.$Env:USERDNSDOMAIN"
                }
                $result = New-Website $AppName `
                    -PhysicalPath $PhysicalPath `
                    -ApplicationPool $AppName `
                    -HostHeader "$AppName.$DefaultBindingSuffix"

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
            
            Write-Verbose 'Successfully ensured IIS site and AppPool'
        }
        else {
            throw 'Error getting target folder for Web App'
        }
    }
}
