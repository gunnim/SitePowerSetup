<#
.SYNOPSIS
Sets up a gMSA, Sql & IIS with the given project name

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create a new group managed service account in Active Directory.
- Install the gMSA locally and on the specified IISServers.
- Create an Sql login and database in the specified SqlDevelopmentServers, and then grant that sql login an sql user and permissions to the newly created database.
- Create an Sql login for the gMSA in the specified SqlProductionServers.
- Create an IIS AppPool running with the gMSA identity locally and on configured IISServers.
- Create an IIS site locally and on configured IISServers using the previously created AppPool
    Local site uses the physicalPath provided via command line or from the displayed prompt
    Default Http bindings are configured in configuration.ps1

The script has been designed to handle cases where some steps have been previously completed.
F.x. if the gMSA has been created previously and the sql data already prepared it is still safe to run the script with the same parameters as before on a new computer.
This would then install the msa locally, create an AppPool and also an iis site, while leaving the previously created Sql data, remote iis sites and AD MSA object as-is.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the MSA, Database and IIS Site.

Setup:
Ensure a security group exists in active directory with the same name as the value for MSAGroupName in configuration.ps1
This security group should contain all servers listed in the IISServers variable

The distinction between SqlDevelopmentServers and SqlProductionServers assumes an environment where during project creation a database is initially created on a development server, and then later restored onto the production Sql server.
In which case creating an initial db on the production server only necessitates it's deletion upon deployment.

.PARAMETER Quiet
Minimal output

.PARAMETER AppName
Web application name

.PARAMETER AccountName
Optional account name, defaults to AppName

.PARAMETER DatabaseName
Optional database name, defaults to AppName

.PARAMETER PhysicalPath
Optionally specify the target directory for the local IIS site to be created.
If not specified the script will display a Windows Forms dialog allowing the directory to be selected.
PhysicalPaths for sites created remotely are always empty

.EXAMPLE
New-SitePowerSetup MyWebApp
Sets up a gMSA, Sql & IIS with the given project name

.EXAMPLE
New-SitePowerSetup MyWebApp MyWebAppAccountName MyWebAppDbName -Quiet
Sets up a gMSA, Sql & IIS using MyWebApp for the IIS site and appPool,
MyWebAppAccountName for the managed service account 
and MyWebAppDbName for the database name 
while suppressing all non fatal output.

.EXAMPLE
New-SitePowerSetup MyWebApp -PhysicalPath E:\MyAppFolder -Verbose
Sets up a gMSA, Sql & IIS with the given project name,
disabling the windows forms select folder dialog by providing an iis target folder from the command line 
and displaying verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-Site
Setup multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
RSAT - It will attempt to install them if missing but this may require a restart.
WebAdministration - Will assume a faulty IIS installation if missing
SqlServer module - Runs Install-Module SqlServer

Managed service accounts require an active directory domain.

If no UI is available the script may appear to hang when prompting for the iis target directory.
In this case specify the PhysicalPath via parameter.

Aliases
- New-Site
- New-App
- ns

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function New-SitePowerSetup {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("New-Site", "New-App", "ns")]
    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0,
                   Mandatory)]
        # So we don't slip a 16 length appName through and assign the AccountName with it during execution, 
        # bypassing validation
        [ValidateLength(1,15)]
        [Alias("Site", "Name")]
        [string]
        $AppName,

        [Parameter(ValueFromPipelineByPropertyName,
                   Position=1)]
        [ValidateLength(1,15)]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $AccountName,

        [Parameter(ValueFromPipelineByPropertyName,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $DatabaseName,

        [Parameter(ValueFromPipelineByPropertyName,
                   Position=3)]
        [ValidateNotNullOrEmpty()]
        [Alias("Path", "Directory", "Folder")]
        [string]
        $PhysicalPath,

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
            [System.Management.Automation.ActionPreference]::Stop

        Test-Sqlcmd
        Test-IISInstallation
        Test-AdminRights
    }

    Process {
        # Init values
        # Done here to support piping of multiple objects
        if ([string]::IsNullOrEmpty($AccountName) -or
        $AccountName -eq '__willreplace__') {
            $AccountName = $AppName
        }
        if ([string]::IsNullOrEmpty($DatabaseName) -or
        $DatabaseName -eq '__willreplace__') {
            $DatabaseName = $AppName
        }

        New-MsaSetup -AccountName $AccountName -Quiet:$Quiet
    
        New-SqlSetup `
            -AccountName $AccountName `
            -DatabaseName $DatabaseName `
            -Quiet:$Quiet
    
        New-IISSetup `
            -AppName $AppName `
            -AccountName $AccountName `
            -PhysicalPath $PhysicalPath `
            -Quiet:$Quiet

        # Without this the following variables will keep their value on subsequent iterations of the process block
        $AccountName = '__willreplace__'
        $DatabaseName = '__willreplace__'

        Write-Verbose "Successfully ensured existence of MSA, Sql data and IIS Site + AppPool for $AppName"
    }
}
