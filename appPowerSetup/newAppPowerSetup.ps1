<#
.SYNOPSIS
Sets up Sql & remote IIS with the given project name

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create a database in the specified SqlDevelopmentServers.
- Create an IIS AppPool running with a predefined iis user on the configured IISServers.

The script has been designed to handle cases where some steps have been previously completed.
F.x. if the sql databases are already prepared it is still safe to run the script with the same parameters as before on a new computer.
This would then leave the previously created Sql data and remote iis sites as-is.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the Database and IIS Site.

Unless your iis servers are AD DC's you will need to configure https://devblogs.microsoft.com/scripting/enable-powershell-second-hop-functionality-with-credssp/
to successfully run Install-ADServiceAccount remotely

.PARAMETER Quiet
Minimal output

.PARAMETER AppName
Web application name

.PARAMETER DatabaseName
Optional database name, defaults to AppName

.PARAMETER Credential
Credentials to use for remote authentication to Sql and IIS servers.

.EXAMPLE
New-AppPowerSetup MyWebApp
Sets up Sql & remote IIS with the given project name

.EXAMPLE
New-AppPowerSetup MyWebApp MyWebAppDbName -Quiet
Sets up Sql & remote IIS using MyWebApp for the IIS site and appPool,
MyWebAppDbName for the database name 
while suppressing all non fatal output.

.EXAMPLE
New-AppPowerSetup MyWebApp -Verbose
Sets up Sql & remote IIS with the given project name,
displaying verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-App
Setup multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
RSAT - It will attempt to install them if missing but this may require a restart.
WebAdministration - Will assume a faulty IIS installation if missing
SqlServer module - Runs Install-Module SqlServer

Aliases
- New-Site
- New-App
- ns

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function New-AppPowerSetup {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("New-Site", "New-App", "ns")]
    Param (
        [Parameter(ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0,
            Mandatory)]
        # So we don't slip a 16 length appName through and assign the AccountName with it during execution, 
        # bypassing validation
        [ValidateLength(1, 15)]
        [Alias("Site", "Name")]
        [string]
        $AppName,

        [Parameter(ValueFromPipelineByPropertyName,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $DatabaseName,

        [Parameter(ValueFromPipelineByPropertyName,
            Position = 4)]
        [System.Management.Automation.PSCredential]
        $Credential,

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
        if ([string]::IsNullOrEmpty($DatabaseName) -or
            $DatabaseName -eq '__willreplace__') {
            $DatabaseName = $AppName
        }

        New-SqlSetup `
            -DatabaseName $DatabaseName `
            -Quiet:$Quiet
    
        New-IISSetup `
            -AppName $AppName `
            -Quiet:$Quiet

        # Without this the following variables will keep their value on subsequent iterations of the process block
        $DatabaseName = '__willreplace__'

        Write-Verbose "Successfully ensured existence of Sql data and IIS Site + AppPool for $AppName"
    }
}
