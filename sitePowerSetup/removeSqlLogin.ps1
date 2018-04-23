function Remove-SqlLogin {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [switch] $Quiet,
        [string] $SqlServer, 
        [string] $SqlLogin
    )
    try {
        if ($PSCmdlet.ShouldProcess("Drop login $Env:USERDOMAIN\$SqlLogin on $SqlServer ?")) {
            Invoke-Sqlcmd -ServerInstance $SqlServer -Query "DROP LOGIN [$Env:USERDOMAIN\$SqlLogin$]" -Database "master"
        }
    }
    catch {
        if ($_.Exception.InnerException -ne $null) {
            if ($_.Exception.InnerException.Number -eq 15151 `
            -Or $_.Exception.InnerException.Number -eq 15401 ) {
                if (-Not $Quiet) {
                    Write-Warning "Login [$Env:USERDOMAIN\$SqlLogin$] not found on $SqlServer"
                }
                return
            }
        }

        throw $_
    }
}
