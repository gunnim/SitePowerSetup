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
# Invoke-MsaSetup myMsaAccount

#.NOTES
# This script requires administrative rights and remote server administration tools.
# If the tools are not present, the script will attempt to install them.
# If an MSA is created, the script will execute Sync-ADObject to ensure that the target IIS servers can see the object.
# If the MSA already exists in AD, we assume it was created with this script and has therefore already been setup on the configured IIS servers.
##############################
function Invoke-MsaSetup {
    param (
        [switch] $Silent,
        [string] $AccountName = $( Read-Host "Service account name" )
    )

	$ErrorActionPreference = 
		[System.Management.Automation.ActionPreference]::Stop

    Test-AdminRights
    Install-RsatTools

	if (-Not $Silent) {
		Write-host "Creating gMSA" -foregroundcolor green
	}
	
	$adDomain = Get-ADDomain
    $MSAFQDN = $AccountName + $adDomain.DNSRoot

    $accountExists = $False
    try {
        New-ADServiceAccount `
            -name $AccountName `
            -DNSHostName $MSAFQDN `
            -PrincipalsAllowedToRetrieveManagedPassword $MSAGroupName
    }
    catch {
		if (-Not $Silent) {
			Write-Warning "MSA already present in active directory"
		}
		$accountExists = $True
    }

    Install-ADServiceAccount $AccountName

    if (-Not $accountExists) {
        $msa = Get-ADServiceAccount $AccountName
        $curDC = Get-ADDomainController
        Get-ADDomainController `
            -filter { HostName -ne $curDC.HostName } | 
            ForEach-Object {
            Sync-ADObject -Object $msa `
                -source $curDC.HostName `
                -Destination $_.hostname
        } 

        Invoke-Command `
            -ComputerName $IISServers `
            -ScriptBlock {param($p1) Install-ADServiceAccount $p1} `
            -ArgumentList $AccountName
    }
}
