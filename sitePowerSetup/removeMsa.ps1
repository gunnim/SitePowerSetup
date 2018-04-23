function Remove-MSA {
    [CmdletBinding(SupportsShouldProcess, 
        ConfirmImpact = 'Medium')]
    param (
        [switch] $Quiet,
        [string] $AccountName
    )

    Begin {
        # We do this to allow Quiet to silence Remove-AdServiceAccount without 
        # disabling the -WhatIf param
        if (-Not $WhatIfPreference -and $Quiet) {
            $ConfirmPreference = 'None'
        }
    }

    Process {

        try {
            $msa = Get-ADServiceAccount -Filter "samAccountName -eq '$AccountName$' "
    
            if ($msa -ne $null -and
            $PSCmdlet.ShouldProcess("Remove-ADServiceAccount $AccountName ?")) {
                Remove-ADServiceAccount $msa -Confirm:$False
            }
            elseIf ($msa -eq $null -and (-Not $Quiet)) {
                Write-Warning "MSA $AccountName not found in AD"
            }
        }
        catch {
            if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound) {
                if (-Not $Quiet) {
                    Write-Warning "MSA $AccountName not found in AD"
                }
                return
            }
    
            throw $_
        }
    }
}
