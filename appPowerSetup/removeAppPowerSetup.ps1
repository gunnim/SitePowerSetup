<#
.SYNOPSIS
Deletes a previously created IIS site and related Sql data.

.DESCRIPTION
This script will attempt the following tasks:
- Remove the project database from the specified SqlDevelopmentServers, disconnecting active sessions from the databases if necessary.
- Remove IIS AppPools on configured IISServers for the given project.
- Remove IIS Sites on configured IISServers for the given project.

The script has been designed to handle cases were some steps have been previously completed.
F.x. if the sql data was already deleted it is still safe to run the script with the same parameters as before on a new computer.
This would then remove the remote IIS AppPool and site, notifying of any errors encountered when deleting Sql or AD data.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the Database and IIS Site.

The script deletes databases from SqlDevelopmentServers.

This scripts primary use case is cleaning up mock sites created for testing, f.x. of the creation script itself.

.PARAMETER Quiet
Minimal output & will forcibly disconnect current database connections before deleting!

.PARAMETER AppName
Web application name

.PARAMETER DatabaseName
Optional database name, defaults to AppName

.EXAMPLE
Remove-AppPowerSetup MyWebApp
Deletes previously created IIS sites and related Sql data.

.EXAMPLE
Remove-AppPowerSetup MyWebApp MyWebAppDbName -Quiet
Deletes a previously created iis site and AppPool named MyWebApp
and sql database with the name MyWebAppDbName
while suppressing all non fatal output.

.EXAMPLE
Remove-AppPowerSetup MyWebApp -Verbose
Deletes a previously created IIS site and related Sql data while
displaying verbose information during script execution.

.Example
'Site1','Site2' | Remove-Site
Remove multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
RSAT - It will attempt to install them if missing but this may require a restart.
WebAdministration - Will assume a faulty IIS installation if missing
SqlServer module - Runs Install-Module SqlServer

Aliases
- Remove-Site
- Remove-App
- rs

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function Remove-AppPowerSetup {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("Remove-Site", "Remove-App", "rs")]

    Param (
        [Parameter(ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0,
            Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName,

        [Parameter(ValueFromPipelineByPropertyName,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $DatabaseName,

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop

        Install-RsatTools
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
   
        foreach ($sqlServer in $SqlDevelopmentServers) {
            Write-Verbose "Removing database $DatabaseName on $sqlServer"
            Remove-Database `
                -DatabaseName $DatabaseName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
        }
    
        foreach ($iisSrv in $IISServers.getEnumerator()) {
            Write-Verbose ("Removing IIS Site + AppPool $AppName on " + $iisSrv.Key)

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

            # Initialize session with required scripts
            Invoke-Command `
                -Session $s `
                -FilePath $PSScriptRoot\testIISInstallation.ps1
            Invoke-Command `
                -Session $s `
                -FilePath $PSScriptRoot\removeIIS.ps1

            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                Test-IISInstallation
            }            
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                Remove-WebAppPoolHelper `
                    -AppName $Using:AppName `
                    -Quiet:$Using:Quiet    
            }
            Invoke-Command `
                -Session $s `
                -ScriptBlock {
                Remove-WebSiteHelper `
                    -AppName $Using:AppName `
                    -Quiet:$Using:Quiet    
            }

            Remove-PSSession $s
        }

        # Without this the following variables will keep their value on subsequent iterations of the process block
        $DatabaseName = '__willreplace__'

        Write-Verbose "Successfully ensured non-existence of Sql data and IIS Site + AppPool for $AppName"
    }
}
