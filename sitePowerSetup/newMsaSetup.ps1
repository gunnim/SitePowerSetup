<#
.SYNOPSIS
Sets up a gMSA with the given project name

.DESCRIPTION
Please edit configuration.ps1 before first use!

This script will attempt the following tasks:
- Create a new group managed service account in Active Directory.
- Install the gMSA locally and on the specified IISServers.

This script fully supports the -WhatIf parameter but also -Confirm and -Verbose

Setup:
Ensure a security group exists in active directory with the same name as the value for MSAGroupName in configuration.ps1
This security group should contain all servers listed in the IISServers variable

.PARAMETER AccountName
Managed service account name

.PARAMETER Quiet
Minimal output

.EXAMPLE
New-MsaSetup MyWebApp
Sets up a gMSA with the given project name

.EXAMPLE
New-MsaSetup MyWebApp MyWebAppAccountName -Quiet
Sets up a gMSA, Sql & IIS using MyWebApp for the IIS site and appPool,
MyWebAppAccountName for the managed service account 
while suppressing all non fatal output.

.EXAMPLE
New-MsaSetup MyWebApp -Verbose
Sets up a gMSA with the given project name,
displaying verbose information during script execution.

.EXAMPLE
'Site1','Site2' | New-MsaSetup
Setup multiple sites

.NOTES
This script requires elevated status.

This script requires the following tools:
RSAT - It will attempt to install them if missing but this may require a restart.

Managed service accounts require an active directory domain.

.LINK
https://github.com/gunnim/SitePowerSetup
#>
function New-MsaSetup {
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

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
		    [System.Management.Automation.ActionPreference]::Stop

        Test-AdminRights
        Install-RsatTools
    }

    Process {
        Write-Verbose "Creating group managed service account"

        $adDomain = Get-ADDomain
        $curDC = Get-ADDomainController
        $MSAFQDN = "$AccountName." + $adDomain.DNSRoot
    
        $msa = Get-ADServiceAccount -Filter "samAccountName -eq '$AccountName$' " -Server $curDC

        if ($msa -eq $null) {
            New-ADServiceAccount `
                -Name $AccountName `
                -DNSHostName $MSAFQDN `
                -PrincipalsAllowedToRetrieveManagedPassword $MSAGroupName `
                -Server $curDC
        
            $msa = Get-ADServiceAccount -Filter "samAccountName -eq '$AccountName$' " -Server $curDC
        }
        else {
            if (-Not $Quiet) {
                Write-Warning "MSA already present in active directory"
            }
        }
        
        if (-not $WhatIfPreference) {
            Get-ADDomainController `
                -Filter { (HostName -ne $curDC.HostName) -and (Hostname -ne "THANOS.intra.vettvangur.is") } | 
            ForEach-Object {
                Sync-ADObject `
                    -Object $msa `
                    -Source $curDC.HostName `
                    -Destination $_.hostname
            }

            foreach ($iisSrv in $IISServers.getEnumerator()) {
                Invoke-Command `
                    -ComputerName $iisSrv.Key `
                    -ScriptBlock {
                        Install-ADServiceAccount `
                            -Identity ($Using:msa).DistinguishedName
                    }
            }
        }
        elseIf ($WhatIfPreference) {
            Write-Output ("What if: Would be Syncing AD-Object and Invoking Install-ADServiceAccount on " + $IISServers.Keys)
        }

        if ($WhatIfPreference) {
            Write-Output "What if: Would run Install-ADServiceAccount locally for the created MSA"
        }
        else {
            Install-ADServiceAccount -Identity $msa
        }
    }
}
