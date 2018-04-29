<#
.SYNOPSIS
Deletes a previously created MSA, local IIS site and related Sql data.

.DESCRIPTION
This script will attempt the following tasks:
- Delete the previously created group managed service account from active directory.
- Remove the msa Sql login and project database from the specified SqlDevelopmentServers & SqlProductionServers, disconnecting active sessions from the databases if necessary.
- Remove the local IIS AppPool for the given project.
- Remove the local IIS Site for the given project.

The script has been designed to handle cases were some steps have been previously completed.
F.x. if the gMSA has been removed previously and the sql data already deleted it is still safe to run the script with the same parameters as before on a new computer.
This would then remove the local IIS AppPool and site, notifying of any errors encountered when deleting Sql or AD data.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

By default the script will use the same name for the MSA, Database and IIS Site.

The script deletes sql logins and databases from SqlDevelopmentServers, only deleting logins on SqlProductionServers.

The distinction given to SqlDevelopmentServers and SqlProductionServers in the New-SitePowerSetup script is not seen the same way during removal.
This script will attempt to remove databases by the given name from both development & production servers!

This scripts primary use case is cleaning up mock sites created for testing, f.x. of the creation script itself.

.PARAMETER Quiet
Minimal output & will forcibly disconnect current database connections before deleting!

.PARAMETER AppName
Web application name

.PARAMETER AccountName
Optional account name, defaults to AppName

.PARAMETER DatabaseName
Optional database name, defaults to AppName

.EXAMPLE
Remove-SitePowerSetup MyWebApp
Deletes a previously created MSA, local IIS site and related Sql data.

.EXAMPLE
Remove-SitePowerSetup MyWebApp MyWebAppAccountName MyWebAppDbName -Quiet
Deletes a previously created iis site and AppPool named MyWebApp
managed service account with the name MyWebAppAccountName and
sql database with the name MyWebAppDbName
while suppressing all non fatal output.

.EXAMPLE
Remove-SitePowerSetup MyWebApp -Verbose
Deletes a previously created MSA, local IIS site and related Sql data while
displaying verbose information during script execution.

.Example
Site1,Site2 | Remove-Site
Remove multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
RSAT - It will attempt to install them if missing but this may require a restart.
WebAdministration - Will assume a faulty IIS installation if missing
SqlServer module - Suggests Install-module SqlServer

Aliases
- Remove-Site
- Remove-App
- rs

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function Remove-SitePowerSetup {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("Remove-Site", "Remove-App", "rs")]

    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0,
                   Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName,

        [Parameter(ValueFromPipelineByPropertyName,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $AccountName,

        [Parameter(ValueFromPipelineByPropertyName,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $DatabaseName,

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
        if ([string]::IsNullOrEmpty($AccountName)) {
            $AccountName = $AppName
        }
        if ([string]::IsNullOrEmpty($DatabaseName)) {
            $DatabaseName = $AppName
        }

        Write-Verbose 'Removing Managed Service Account'
    
        Remove-MSA -AccountName $AccountName -Quiet:$Quiet
    
        foreach ($sqlServer in $SqlDevelopmentServers) {
            Write-Verbose "Removing SQL login & database on $sqlServer"
            Remove-Database `
                -DatabaseName $DatabaseName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
            Remove-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
        }
    
        foreach ($sqlServer in $SqlProductionServers) {
            Write-Verbose "Removing SQL login on $sqlServer"
            Remove-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
        }
    
        Write-Verbose 'Removing IIS site + AppPool'
    
        Remove-WebAppPoolHelper -AppName $AppName -Quiet:$Quiet
        Remove-WebSiteHelper -AppName $AppName -Quiet:$Quiet

        foreach ($iisSrv in $IISServers.getEnumerator()) {
            Write-Verbose ("Removing IIS Site + AppPool on " + $iisSrv.Key)

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

        Write-Verbose "Successfully ensured non-existence of MSA, Sql data and IIS Site + AppPool for $AppName"
    }
}
