Set-StrictMode -Version 2.0

# Sql servers where we create an sql login, database and sql user in db
$SqlDatabaseServers = @(
)
# Sql servers where we only create an sql login
$SqlLoginServers = @(
)
# IIS servers that will host the MSA
$IISServers = @(
)
# Active Directory security group of which member computers have the right to host the MSA
$MSAGroupName = 'IIS Servers'

# Default = "localhost.$Env:USERDNSDOMAIN"
#$DefaultBindingSuffix = 'localhost.mydomain.com'

. $PSScriptRoot\getFolder.ps1
. $PSScriptRoot\installRsatTools.ps1
. $PSScriptRoot\invokeIISSetup.ps1
. $PSScriptRoot\invokeMsaSetup.ps1
. $PSScriptRoot\invokeSqlSetup.ps1
. $PSScriptRoot\invokeSitePowerSetup.ps1
. $PSScriptRoot\removeIIS.ps1
. $PSScriptRoot\removeMsa.ps1
. $PSScriptRoot\removeSite.ps1
. $PSScriptRoot\removeSqlLogin.ps1
. $PSScriptRoot\sqlHelpers.ps1
. $PSScriptRoot\testAdminRights.ps1
. $PSScriptRoot\testIISInstallation.ps1
