<#
.SYNOPSIS
Sets up an IIS Site & AppPool on configured IISServers

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create an IIS AppPool on configured IISServers.
- Create an IIS site on configured IISServers using the previously created AppPool
    Default Http bindings are configured in configuration.ps1

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the IIS Site & AppPool identity.

Setup:
Ensure a security group exists in active directory with the same name as the value for MSAGroupName in configuration.ps1
This security group should contain all servers listed in the IISServers variable

.PARAMETER AppName
Web application name

.PARAMETER Quiet
Minimal output

.EXAMPLE
New-IISSetup MyWebApp
Sets up an IIS Site & AppPool on configured IISServers

.EXAMPLE
New-IISSetup MyWebApp MyWebAppAccountName -Quiet
Sets up IIS using MyWebApp for the IIS site and appPool,
while suppressing all non fatal output.

.EXAMPLE
New-IISSetup MyWebApp -Verbose
Sets up an IIS Site & AppPool on configured IISServers and
displays verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-IISSetup
Setup multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
WebAdministration - Will assume a faulty IIS installation if missing

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function New-IISSetup {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0,
            Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName,
        
        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
        Test-IISInstallation
        Test-AdminRights
    }

    Process {

        $path = $null
        if ($null -ne $IISServerDefaultFilePath) {
            $path = "$IISServerDefaultFilePath\$AppName"
        }

        foreach ($iisSrv in $IISServers.getEnumerator()) {
            Write-Verbose ("Creating IIS Site + AppPool $AppName on " + $iisSrv.Key)
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
                    -IISUsername $Using:IISUsername `
                    -IISPassword $Using:IISPassword `
                    -Quiet:$Using:Quiet    
            }
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                New-WebSiteHelper `
                    -AppName $Using:AppName `
                    -PhysicalPath $Using:path `
                    -Binding ($Using:iisSrv).Value `
                    -Quiet:$Using:Quiet    
            }

            Remove-PSSession $s
        }
    }
}
