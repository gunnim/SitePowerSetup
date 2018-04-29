Set-StrictMode -Version 2.0

. $PSScriptRoot\configuration.ps1
. $PSScriptRoot\formatBinding.ps1
. $PSScriptRoot\getFolder.ps1
. $PSScriptRoot\iisHelpers.ps1
. $PSScriptRoot\installRsatTools.ps1
. $PSScriptRoot\newIISSetup.ps1
. $PSScriptRoot\newMsaSetup.ps1
. $PSScriptRoot\newSitePowerSetup.ps1
. $PSScriptRoot\newSqlSetup.ps1
. $PSScriptRoot\removeDatabase.ps1
. $PSScriptRoot\removeIIS.ps1
. $PSScriptRoot\removeMsa.ps1
. $PSScriptRoot\removeSitePowerSetup.ps1
. $PSScriptRoot\removeSqlLogin.ps1
. $PSScriptRoot\sqlHelpers.ps1
. $PSScriptRoot\testAdminRights.ps1
. $PSScriptRoot\testIISInstallation.ps1
. $PSScriptRoot\testSqlcmd.ps1

# Ignore the following, it allows me to keep a gitignored server configuration in local project folder :)
if ( Test-Path $PSScriptRoot\customisations.ps1) {
    . $PSScriptRoot\customisations.ps1
}
