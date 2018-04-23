function New-Database {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [switch] $Quiet,
        [string] $SqlServer, 
        [string] $DatabaseName
    )

    try {
        if ($PSCmdlet.ShouldProcess("Create new database $DatabaseName on $SqlServer ?")) {
            Invoke-Sqlcmd -ServerInstance $SqlServer -Query "CREATE DATABASE [$DatabaseName]"
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
            Invoke-Sqlcmd -ServerInstance $SqlServer -Query "create login [$Env:USERDOMAIN\$SqlLogin$] FROM WINDOWS" -Database "master"
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
                -Database $DatabaseName
            Invoke-Sqlcmd `
                -ServerInstance $SqlServer `
                -Query "EXEC sp_addrolemember 'db_owner', '$Env:USERDOMAIN\$SqlUser$';" `
                -Database $DatabaseName
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

# Currently unused
function New-Table($SqlServer, $Database, $query) {
    try {
        Invoke-Sqlcmd `
            -ServerInstance $SqlServer `
            -Query $query `
            -Database $Database
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 2714) {
                # $queryFirstLine = $query.Split('\n')[0]
                # Write-Warning "Error executing query $queryFirstLine for database $Database on $SqlServer"
                return
            }
        }

        throw $_
    }
}
# Currently unused
function New-Index($SqlServer, $Database, $index) {
    try {
        Invoke-Sqlcmd `
            -ServerInstance $SqlServer `
            -Query $index `
            -Database $Database
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 1913) {
                Write-Warning "Index [$Database].[$index] on $SqlServer already present"
                return
            }
        }

        throw $_
    }
}
