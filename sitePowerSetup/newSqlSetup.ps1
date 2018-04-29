<#
.SYNOPSIS
Configures sql servers for the given project

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create an Sql login and database in the specified SqlDevelopmentServers, and then grant that sql login an sql user and permissions to the newly created database.
- Create an Sql login for the gMSA in the specified SqlProductionServers.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the database & account name.

The distinction between SqlDevelopmentServers and SqlProductionServers assumes an environment where during project creation a database is initially created on a development server, and then later restored onto the production Sql server.
In which case creating an initial db on the production server only necessitates it's deletion upon deployment.

.PARAMETER AccountName
Managed service account name

.PARAMETER DatabaseName
Optional database name, defaults to AppName

.PARAMETER Quiet
Minimal output

.EXAMPLE
New-SqlSetup MyWebAppAccountName
Configures sql servers for the given project

.EXAMPLE
New-SqlSetup MyWebAppAccountName MyWebAppDbName -Quiet
Configures sql servers for the given project using MyWebAppAccountName for the managed service account 
and MyWebAppDbName for the database name 
while suppressing all non fatal output.

.EXAMPLE
New-SqlSetup MyWebAppAccountName -Verbose
Configures sql servers for the given project,
disabling the windows forms select folder dialog by providing an iis target folder from the command line 
and displaying verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-SqlSetup
Configures sql servers for multiple projects

.NOTES
This script requires elevated status.

This script requires the following tools:
SqlServer module - Suggests Install-module SqlServer

Managed service accounts require an active directory domain.

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function New-SqlSetup {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0,
                   Mandatory)]
        [ValidateLength(1,15)]
        [Alias("Name")]
        [string]
        $AccountName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [PSDefaultValue(Help = 'Uses AccountName by default')]
        [string]
        $DatabaseName,

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
        Test-Sqlcmd
        Test-AdminRights
    }

    Process {
        if ([string]::IsNullOrEmpty($DatabaseName) -or
        $DatabaseName -eq '__change_me__') {
            $DatabaseName = $AccountName
        }

        foreach ($sqlServer in $SqlDevelopmentServers) {
            Write-Verbose "Creating sql database $DatabaseName, login & user [$Env:USERDOMAIN\$AccountName$] on $sqlServer"
            New-Database `
                -SqlServer $sqlServer `
                -DatabaseName $DatabaseName `
                -Quiet:$Quiet
            New-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
            New-SqlUser `
                -SqlUser $AccountName `
                -SqlServer $sqlServer `
                -Database $DatabaseName `
                -Quiet:$Quiet
            }
    
        foreach ($sqlServer in $SqlProductionServers) {
            Write-Verbose "Creating sql login [$Env:USERDOMAIN\$AccountName$] on $sqlServer"
            New-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
        }

        # Without this DatabaseName will keep it's value on subsequent iterations of the process block
        $DatabaseName = '__change_me__'
    }
}
