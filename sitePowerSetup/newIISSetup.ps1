<#
.SYNOPSIS
Sets up an IIS Site & AppPool locally and on configured IISServers

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create an IIS AppPool running with the gMSA identity locally and on configured IISServers.
- Create an IIS site locally and on configured IISServers using the previously created AppPool
    Local site uses the physicalPath provided via command line or from the displayed prompt
    Default Http bindings are configured in configuration.ps1

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the IIS Site & AppPool identity.

Setup:
Ensure a security group exists in active directory with the same name as the value for MSAGroupName in configuration.ps1
This security group should contain all servers listed in the IISServers variable

.PARAMETER AppName
Web application name

.PARAMETER AccountName
Optional account name, defaults to AppName

.PARAMETER PhysicalPath
Optionally specify the target directory for the local IIS site to be created.
If not specified the script will display a Windows Forms dialog allowing the directory to be selected.
PhysicalPaths for sites created remotely are always empty

.PARAMETER Quiet
Minimal output

.EXAMPLE
New-IISSetup MyWebApp
Sets up an IIS Site & AppPool locally and on configured IISServers

.EXAMPLE
New-IISSetup MyWebApp MyWebAppAccountName -Quiet
Sets up a gMSA, Sql & IIS using MyWebApp for the IIS site and appPool,
MyWebAppAccountName for the managed service account 
while suppressing all non fatal output.

.EXAMPLE
New-IISSetup MyWebApp -PhysicalPath E:\MyAppFolder -Verbose
Sets up an IIS Site & AppPool locally and on configured IISServers,
disables the windows forms select folder dialog by providing an iis target folder from the command line 
and displays verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-IISSetup
Setup multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
WebAdministration - Will assume a faulty IIS installation if missing

Managed service accounts require an active directory domain.

If no UI is available the script may appear to hang when prompting for the iis target directory.
In this case specify the PhysicalPath via parameter.

.LINK
https://github.com/gunnim/SitePowerSetup
#>
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
        if ([string]::IsNullOrEmpty($AccountName) -or
        $AccountName -eq '__willreplace__') {
            $AccountName = $AppName
        }

        if ([string]::IsNullOrEmpty($PhysicalPath)) {
            $PhysicalPath = Get-Folder
        }
        elseIf (-Not (Test-Path $PhysicalPath)) {
            Write-Warning 'Invalid path supplied'
            $PhysicalPath = Get-Folder
        }

        Write-Verbose "Creating IIS site + AppPool $AppName locally"

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
                        -AccountName $Using:AccountName `
                        -Quiet:$Using:Quiet    
                }
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                    New-WebSiteHelper `
                        -AppName $Using:AppName `
                        -PhysicalPath $null `
                        -Binding ($Using:iisSrv).Value `
                        -Quiet:$Using:Quiet    
                }

            Remove-PSSession $s
        }

        # Without this AccountName will keep it's value on subsequent iterations of the process block
        $AccountName = '__willreplace__'
    }
}
