function New-SqlSetup {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")]
        [string]
        $AccountName = $( Read-Host "Service account name" ),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AccountName by default')]
        [string]
        $DatabaseName = $AccountName,

        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
        Test-Sqlcmd
        Test-AdminRights
    }

    Process {
        foreach ($sqlServer in $SqlDatabaseServers) {
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
            Write-Verbose "Ensured sql database, login & user on $sqlServer"
        }
    
        foreach ($sqlServer in $SqlLoginServers) {
            New-SqlLogin `
                -SqlLogin $AccountName `
                -SqlServer $sqlServer `
                -Quiet:$Quiet
            Write-Verbose "Ensured sql login on $sqlServer"
        }
    }
}
