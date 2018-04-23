##############################
#.SYNOPSIS
#Short description
#
#.DESCRIPTION
#Long description
#
#.PARAMETER Silent
# Minimal output
#
#.PARAMETER AppName
# Web application name
#
#.PARAMETER AccountName
# Optional account name, defaults to AppName
#
#.PARAMETER DatabaseName
# Optional database name, defaults to AppName
#
#.EXAMPLE
# Invoke-WebAppSetup MyWebApp
#
#.NOTES
#General notes
##############################
function New-SitePowerSetup {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("New-Site", "New-App")]
    param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName = $( Read-Host "Web application name" ),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $AccountName = $AppName,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [string]
        $DatabaseName = $AppName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("Path", "Directory", "Folder")]
        [string]
        $PhysicalPath,

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
        Write-Verbose 'Preparing to install Managed Service Account'
    
        New-MsaSetup -AccountName $AccountName -Quiet:$Quiet
    
        Write-Verbose 'Preparing to create SQL databases, logins and users'
    
        New-SqlSetup `
            -AccountName $AccountName `
            -DatabaseName $DatabaseName `
            -Quiet:$Quiet
    
        Write-Verbose 'Preparing to create IIS site + AppPool'
    
        New-IISSetup `
            -AppName $AppName `
            -AccountName $AccountName `
            -PhysicalPath $PhysicalPath `
            -Quiet:$Quiet

        Write-Verbose "Successfully ensured existence of MSA, Sql data and IIS Site + AppPool for $AppName"
    }
}
