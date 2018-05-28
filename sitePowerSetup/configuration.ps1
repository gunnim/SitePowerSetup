# Sql servers where we create an sql login, database and sql user in db
$script:SqlDevelopmentServers = @(
    # 'myDevSqlServer',
)

# Sql servers where we create an sql login, and create an sql user if the database already exists.
$script:SqlProductionServers = @(
)

# Hash table of IIS servers that will host the MSA
# All servers should be members of the MSAGroupName AD security group configured below
# Key is the iis server hostname
# Value becomes the site binding
# Substitutions:
# %s AppName
# %n A random 3 digit number
# %d $Env:UserDnsDomain
# Leaving empty uses the LocalSiteBinding
# That way we never create sites with empty bindings overriding the Default Web Site
$script:IISServers = @{
#    'IISSrv1' = "%s-%n.test.domain.info"
#    'IISSrv2' = "%s.staging.%d"
}
$script:LocalSiteBinding = '%s.localhost.%d'

# Create am Active Directory security group that matches the configured value below.
# This group should contain all computers allowed to host the MSA.
# In addition to dedicated IIS servers, 
# all development workstations that might run these scripts will also need to be members of the group.
$script:MSAGroupName = 'IIS Servers'

# Path to the latest windows RSAT for desktop systems
# Grab from here https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520
$script:RSATFilePath = '\\srv1\fileShare\WindowsTH-RSAT_WS_1709-x64.msu'
