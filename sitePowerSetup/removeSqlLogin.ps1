function Remove-SqlLogin {
    param (
        [switch] $Silent,
        [string] $SqlServer, 
        [string] $SqlLogin
    )
    try {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query "DROP LOGIN [$Env:USERDOMAIN\$SqlLogin$]" -Database "master"
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 15151 `
            -Or $_.Exception.InnerException.Number -eq 15401 ) {
                if (-Not $Silent) {
                    Write-Warning "Login [$Env:USERDOMAIN\$SqlLogin$] not found on $SqlServer"
                }
                return
            }
        }

        throw $_
    }
}
