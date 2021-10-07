function Remove-Database {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    Param (
        [string] $SqlServer, 
        [string] $DatabaseName,
        [switch] $Quiet
    )

    Process {
        try {
            if (-Not $WhatIfPreference -and $Quiet) {
                Invoke-Sqlcmd -ServerInstance $SqlServer -Query "ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;"
            }
            elseIf ($WhatIfPreference -and $Quiet) {
                Write-Output "What if: Would run ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; on $SqlServer"
            }

            if ($PSCmdlet.ShouldProcess("Drop database $DatabaseName on server $SqlServer ?")) {
                Invoke-Sqlcmd -ServerInstance $SqlServer -Query "DROP DATABASE [$DatabaseName]"
            }
        }
        catch {
            if ($_.Exception.InnerException -ne $null) {
                if ($_.Exception.InnerException.Number -eq 3701 -or
                $_.Exception.InnerException.Number -eq 5011) {
                    if (-Not $Quiet) {
                        Write-Warning "Database [$DatabaseName] on $SqlServer not found"
                    }
                    return
                }
                elseIf ($_.Exception.InnerException.Number -eq 3702) {
                    return Remove-DatabaseWithForce @PSBoundParameters
                }
            }
        
            throw $_
        }
    }
}

function Remove-DatabaseWithForce {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param (
        [string] $SqlServer, 
        [string] $DatabaseName,
        [switch] $Quiet
    )
    
    if ($PSCmdlet.ShouldProcess("Database currently in use, forcibly disconnect current sessions?")) {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query "ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;"
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query "DROP DATABASE [$DatabaseName]"
    }  
}
