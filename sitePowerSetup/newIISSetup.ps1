function New-IISSetup {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0,
                   Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateLength(1,15)]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $AccountName,

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
        if ([string]::IsNullOrEmpty($AccountName)) {
            $AccountName = $AppName
        }

        if ([string]::IsNullOrEmpty($null)) {
            $PhysicalPath = Get-Folder
        }
        elseIf (-Not (Test-Path $PhysicalPath)) {
            Write-Warning 'Invalid path supplied'
            $PhysicalPath = Get-Folder
        }

        # Local IIS setup
        New-WebAppPoolHelper `
            -AppName $AppName `
            -AccountName $AccountName `
            -Quiet:$Quiet
        New-WebSiteHelper `
            -AppName $AppName `
            -PhysicalPath $PhysicalPath `
            -Binding $LocalSiteBinding `
            -Quiet:$Quiet

        foreach ($iisSrv in $IISServers.getEnumerator()) {
            $s = New-PSSession -ComputerName $iisSrv.Key

            # Copy local preferences over to session
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                    $ConfirmPreference = $Using:ConfirmPreference
                    $WhatIfPreference = $Using:WhatIfPreference
                    $ErrorActionPreference = $Using:ErrorActionPreference
                    $VerbosePreference = $Using:VerbosePreference
                }

            Invoke-Command `
                -Session $s `
                -FilePath $PSScriptRoot\testIISInstallation.ps1
            Invoke-Command `
                -Session $s `
                -FilePath $PSScriptRoot\formatBinding.ps1
            Invoke-Command `
                -Session $s `
                -FilePath $PSScriptRoot\iisHelpers.ps1

            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                    Test-IISInstallation
                }            
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                    New-WebAppPoolHelper `
                        -AppName $Using:AppName `
                        -AccountName $Using:AccountName `
                        -Quiet:$Using:Quiet    
                }
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                    New-WebSiteHelper `
                        -AppName $Using:AppName `
                        -PhysicalPath $Using:PhysicalPath `
                        -Binding ($Using:iisSrv).Value `
                        -Quiet:$Using:Quiet    
                }

            Remove-PSSession $s
        }

        Write-Verbose 'Successfully ensured IIS site and AppPool'
    }
}
