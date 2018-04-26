function Remove-SitePowerSetup {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("Remove-Site", "Remove-App")]

    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName = $( Read-Host "Web application name" ),
        
        [Parameter(ValueFromPipelineByPropertyName,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $AccountName = $AppName,
        
        [Parameter(ValueFromPipelineByPropertyName,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $DatabaseName = $AppName,

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
        Write-Verbose 'Preparing to remove Managed Service Account'
    
        Remove-MSA -AccountName $AccountName -Quiet:$Quiet
    
        Write-Verbose 'Preparing to remove SQL login & database'
    
        foreach ($sqlServer in $SqlDatabaseServers) {
            Remove-Database `
                -SqlServer $sqlServer `
                -DatabaseName $DatabaseName `
                -Quiet:$Quiet
            Remove-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
        }
    
        foreach ($sqlServer in $SqlLoginServers) {
            Remove-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
        }
    
        Write-Verbose "Ensured non-existence of sql data"
    
        Write-Verbose 'Preparing to remove IIS site + AppPool'
    
        Remove-WebAppPoolHelper -AppName $AppName -Quiet:$Quiet
        Remove-WebSiteHelper -AppName $AppName -Quiet:$Quiet

        Write-Verbose "Successfully ensured non-existence of MSA, Sql data and IIS Site + AppPool for $AppName"
    }
}
