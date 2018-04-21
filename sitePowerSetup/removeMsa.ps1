function Remove-MSA {
    param (
        [switch] $Silent,
        [string] $AccountName
    )

    try {
        Remove-ADServiceAccount $AccountName -Confirm:$false
    }
    catch {
        if ($_.CategoryInfo -ne $null) {
            if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound) {
                if (-Not $Silent) {
                    Write-Warning "MSA $AccountName not found in AD"
                }
                return
            }
        }

        throw $_
    }
}
