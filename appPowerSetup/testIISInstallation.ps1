function Test-IISInstallation {

    $hasWebAdministration = 
        Get-Command `
        -Name New-Website `
        -ErrorAction SilentlyContinue

    if ($hasWebAdministration -eq $null) {
        throw 'IIS PowerShell commands missing, please install/reinstall IIS'
    }
}
