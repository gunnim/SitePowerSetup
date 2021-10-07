# Sql servers where we create a database
$script:SqlDevelopmentServers = @(
    # 'myDevSqlServer',
)

# Hash table of IIS servers
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
# Yep this should probably be per server..
$script:IISServerDefaultFilePath = $null
$script:IISUsername = 'domain\iisuser'
$script:IISPassword = 'pwd'

# Path to the latest windows RSAT for desktop systems
# Grab from here https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520
$script:RSATFilePath = '\\srv1\fileShare\WindowsTH-RSAT_WS_1709-x64.msu'
