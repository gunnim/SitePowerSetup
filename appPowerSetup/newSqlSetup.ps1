<#
.SYNOPSIS
Configures sql servers for the given project

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create a database in the specified SqlDevelopmentServers.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

.PARAMETER DatabaseName
Optional database name, defaults to AppName

.PARAMETER Quiet
Minimal output

.EXAMPLE
New-SqlSetup MyWebAppDbName
Configures sql servers for the given project

.EXAMPLE
New-SqlSetup MyWebAppDbName -Quiet
Configures sql servers for the given project using MyWebAppDbName for the database name 
while suppressing all non fatal output.

.EXAMPLE
New-SqlSetup MyWebAppAccountName -Verbose
Configures sql servers for the given project,
displaying verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-SqlSetup
Configures sql servers for multiple projects

.NOTES
This script requires elevated status.

This script requires the following tools:
SqlServer module - Runs Install-Module SqlServer

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function New-SqlSetup {
    # Required by child cmdlets iirc
    [CmdletBinding(SupportsShouldProcess)]
    Param (
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
        foreach ($sqlServer in $SqlDevelopmentServers) {
            Write-Verbose "Creating sql database $DatabaseName on $sqlServer"
            New-Database `
                -SqlServer $sqlServer `
                -DatabaseName $DatabaseName `
                -Quiet:$Quiet
        }
    }
}
