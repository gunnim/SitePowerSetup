##############################
#.SYNOPSIS
# Creates a group managed service account in active directory
#
#.DESCRIPTION
# This script creates a group managed service account in active directory,
# installs it onto the local computer and also on all configured IIS servers.
#
#.PARAMETER Silent
#Parameter description
#
#.PARAMETER AccountName
#Parameter description
#
#.EXAMPLE
# New-MsaSetup myMsaAccount

#.NOTES
# This script requires administrative rights and remote server administration tools.
# If the tools are not present, the script will attempt to install them.
# If an MSA is created, the script will execute Sync-ADObject to ensure that the target IIS servers can see the object.
# If the MSA already exists in AD, we assume it was created with this script and has therefore already been setup on the configured IIS servers.
##############################
function New-MsaSetup {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")]
        [string]
        $AccountName = $( Read-Host "Service account name" ),

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
		[System.Management.Automation.ActionPreference]::Stop

        Test-AdminRights
        Install-RsatTools
    }

    Process {
        Write-Verbose "Creating gMSA"

        $adDomain = Get-ADDomain
        $curDC = Get-ADDomainController
        $MSAFQDN = "$AccountName." + $adDomain.DNSRoot
    
        $accountExists = $False
        try {
            New-ADServiceAccount `
                -Name $AccountName `
                -DNSHostName $MSAFQDN `
                -PrincipalsAllowedToRetrieveManagedPassword $MSAGroupName `
                -Server $curDC
        }
        catch {
            if (-Not $Quiet) {
                Write-Warning "MSA already present in active directory"
            }
            $accountExists = $True
        }
    
        $msa = Get-ADServiceAccount -Filter "samAccountName -eq '$AccountName$' " -Server $curDC
        
        # If the account already exists, we assume it was created with this script and 
        # has already been synced across the domain
        if (-Not $accountExists -and (-not $WhatIfPreference)) {
            Get-ADDomainController `
                -Filter { HostName -ne $curDC.HostName } | 
            ForEach-Object {
                Sync-ADObject `
                    -Object $msa `
                    -Source $curDC.HostName `
                    -Destination $_.hostname
            }
            
            Invoke-Command `
                -ComputerName $IISServers `
                -ScriptBlock {param($p1) Install-ADServiceAccount -Identity $p1} `
                -ArgumentList $msa.DistinguishedName
        }
        elseIf ($WhatIfPreference) {
            Write-Output "What if: Would be Syncing AD-Object and Invoking Install-ADServiceAccount on $IISServers"
        }

        if ($WhatIfPreference) {
            Write-Output "What if: Would run Install-ADServiceAccount locally for the created MSA"
        }
        else {
            Install-ADServiceAccount -Identity $msa
        }
    }
}