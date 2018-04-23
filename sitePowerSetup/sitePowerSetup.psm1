Set-StrictMode -Version 2.0

# Sql servers where we create an sql login, database and sql user in db
$script:SqlDatabaseServers = @(
)
# Sql servers where we only create an sql login
$script:SqlLoginServers = @(
)
# IIS servers that will host the MSA
$script:IISServers = @(
)
# Active Directory security group of which member computers have the right to host the MSA
$script:MSAGroupName = 'IIS Servers'

#$DefaultBindingSuffix = 'localhost.mydomain.com'

. $PSScriptRoot\getFolder.ps1
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

# Allows me to keep gitignored server configuration in local project folder :)
if ( Test-Path $PSScriptRoot\customisations.ps1) {
    . $PSScriptRoot\customisations.ps1
}
