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
        [ValidateNotNullOrEmpty()]
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
        if ([string]::IsNullOrEmpty($DatabaseName)) {
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
    }
}
