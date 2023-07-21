function New-Database {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [switch] $Quiet,
        [string] $SqlServer, 
        [string] $DatabaseName
    )

    try {
        if ($PSCmdlet.ShouldProcess("Create new database $DatabaseName on $SqlServer ?")) {
            Invoke-Sqlcmd -ServerInstance $SqlServer -Query "CREATE DATABASE [$DatabaseName]" -TrustServerCertificate
        }
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 1801) {
                if (-Not $Quiet) {
                    Write-Warning "Database [$DatabaseName] on $SqlServer already present"
                }
                return
            }
        }

        throw $_
    }
}

function New-SqlLogin {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    Param (
        [Alias("AccountName")]
        [string]
        $SqlLogin,

        [string] $SqlServer,
        [switch] $Quiet
    )

    try {
        if ($PSCmdlet.ShouldProcess("Create login $Env:USERDOMAIN\$SqlLogin$ on $SqlServer ?")) {
            Invoke-Sqlcmd -ServerInstance $SqlServer -Query "create login [$Env:USERDOMAIN\$SqlLogin$] FROM WINDOWS" -Database "master" -TrustServerCertificate
        }
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 15025) {
                if (-Not $Quiet) {
                    Write-Warning "Login [$Env:USERDOMAIN\$SqlLogin$] already present on $SqlServer"
                }
                return
            }
        }

        throw $_
    }
}

function New-SqlUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    Param (
        [Alias("AccountName")]
        [string]
        $SqlUser,

        [string] $SqlServer,
        [string] $DatabaseName,
        [switch] $Quiet
    )
    
    try {
        if ($PSCmdlet.ShouldProcess("Create user $Env:USERDOMAIN\$SqlUser$ on $SqlServer ?")) {
            Invoke-Sqlcmd `
                -ServerInstance $SqlServer `
                -Query "CREATE USER [$Env:USERDOMAIN\$SqlUser$] for login [$Env:USERDOMAIN\$SqlUser$] WITH DEFAULT_SCHEMA=[dbo];" `
                -Database $DatabaseName `
                -TrustServerCertificate
            Invoke-Sqlcmd `
                -ServerInstance $SqlServer `
                -Query "EXEC sp_addrolemember 'db_owner', '$Env:USERDOMAIN\$SqlUser$';" `
                -Database $DatabaseName `
                -TrustServerCertificate
        }
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 15023) {
                if (-Not $Quiet) {
                    Write-Warning "User [$Env:USERDOMAIN\$SqlUser$] for database $DatabaseName already present on $SqlServer"
                }
                return
            }
        }

        throw $_
    }
}
