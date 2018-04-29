# Sql servers where we create an sql login, database and sql user in db
$script:SqlDevelopmentServers = @(
    # 'myDevSqlServer',
)

# Sql servers where we only create an sql login
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
# Leave empty to use the localbinding, this way we never create sites with bindings overriding the Default Web Site
$script:IISServers = @{
#    'IISSrv1' = "%s-%n.test.domain.info"
#    'IISSrv2' = "%s.staging.%d"
}
$script:LocalSiteBinding = '%s.localhost.%d'

# Active Directory security group of which member computers have the right to host the MSA
$script:MSAGroupName = 'IIS Servers'
