function New-Database {
    param (
        [switch] $Silent,
        [string] $SqlServer, 
        [string] $DatabaseName
    )

    try {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query "CREATE DATABASE [$DatabaseName]"
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 1801) {
                if (-Not $Silent) {
                    Write-Warning "Database [$DatabaseName] on $SqlServer already present"
                }
                return
            }
        }

        throw $_
    }
}

function Remove-Database {
    param (
        [switch] $Silent,
        [string] $SqlServer, 
        [string] $DatabaseName
    )

    try {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query "DROP DATABASE [$DatabaseName]"
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 3701) {
                if (-Not $Silent) {
                    Write-Warning "Database [$DatabaseName] on $SqlServer not found"
                }
                return
            }
        }

        throw $_
    }
}

function New-SqlLogin  {
    param (
        [switch] $Silent,
        [string] $SqlLogin,
        [string] $SqlServer
    )

    try {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query "create login [$Env:USERDOMAIN\$SqlLogin$] FROM WINDOWS" -Database "master"
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 15025) {
                if (-Not $Silent) {
                    Write-Warning "Login [$Env:USERDOMAIN\$SqlLogin$] already present on $SqlServer"
                }
                return
            }
        }

        throw $_
    }
}

function New-SqlUser {
    param (
        [switch] $Silent,
        [string] $SqlUser,
        [string] $SqlServer,
        [string] $Database
    )
    
    try {
        Invoke-Sqlcmd `
            -ServerInstance $SqlServer `
            -Query "create user [$Env:USERDOMAIN\$SqlUser$] for login [$Env:USERDOMAIN\$SqlUser$] WITH DEFAULT_SCHEMA=[dbo];" `
            -Database $Database
        Invoke-Sqlcmd `
            -ServerInstance $SqlServer `
            -Query "exec sp_addrolemember 'db_owner', '$Env:USERDOMAIN\$SqlUser$';" `
            -Database $Database
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 15023) {
                if (-Not $Silent) {
                    Write-Warning "User [$Env:USERDOMAIN\$SqlUser$] for database $Database already present on $SqlServer"
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
