<#
.SYNOPSIS
Creates a self-signed certificate for local iis installation

.DESCRIPTION
Creates a self-signed certificate for local iis installation
Requires configuring a LocalSiteBinding using the format as IISServers bindings

.PARAMETER AppName
Web application name

.PARAMETER BindingName
IIS Site binding name

.PARAMETER Quiet
Minimal output

.EXAMPLE
New-IISBinding MyWebApp

.NOTES
This script requires elevated status.
This script requires the following tools:
WebAdministration - Will assume a faulty IIS installation if missing

Requires configuring a LocalSiteBinding using the format as IISServers bindings
#>
function New-IISBinding {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0,
            Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias("Site", "Name")]
        [string]
        $AppName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [PSDefaultValue(Help = 'Uses AppName by default')]
        [Alias("Binding")]
        [string]
        $BindingName,
        
        [switch] $Quiet
    )

    Begin {
        $ErrorActionPreference = 
        [System.Management.Automation.ActionPreference]::Stop
        Test-IISInstallation
        Test-AdminRights
    }
    
    Process {
        Write-Verbose ("Creating self signed certificate and assigning to new https binding for local iis site")

        if ([string]::IsNullOrEmpty($BindingName)) {
            $BindingName = $AppName
        }

        $Binding = Format-Binding $LocalSiteBinding $BindingName

        $prevBinding = Get-IISSiteBinding -Name $AppName `
            -BindingInformation "*:443:$Binding"

        if ($prevBinding -eq $null) {
            $crt = New-SelfSignedCertificate `
                -Subject $Binding `
                -TextExtension @("2.5.29.17={text}DNS=$Binding") `
                -CertStoreLocation "cert:\LocalMachine\My"
    
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
                [System.Security.Cryptography.X509Certificates.StoreName]::Root,
                "localmachine"
            )
            $store.Open(
                [System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly +
                [System.Security.Cryptography.X509Certificates.OpenFlags]::MaxAllowed
            )
            if (-Not $WhatIfPreference) {
                $store.Add($crt)
            }
            $store.Dispose()
    
            if ($WhatIfPreference) {
                Write-Output "What if: Would create New-IISSiteBinding on IIS:\Site\$AppName with BindingInformation '*:443:$Binding'"
            }
            else {
                New-IISSiteBinding -Name $AppName `
                    -BindingInformation "*:443:$Binding" `
                    -CertificateThumbPrint $crt.Thumbprint `
                    -CertStoreLocation "Cert:\LocalMachine\My" `
                    -Protocol https `
                    -SslFlag "Sni"
            }
        }
        elseIf (-Not $Quiet) {
            Write-Warning "IIS site with name $AppName already contains binding *:443:$Binding"
        }
    }
}
