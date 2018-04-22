function Remove-WebAppPoolHelper {
    param (
        [switch] $Silent,
        [string] $AppName
    )

    try {
        Remove-WebAppPool $AppName
    }
    catch {
        if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound) {
            if (-Not $Silent) {
                Write-Warning "IIS AppPool $AppName not found"
                return
            }
        }
        throw $_
    }
}

function Remove-WebSiteHelper {
    param (
        [switch] $Silent,
        [string] $AppName
    )

    try {
        Remove-Website $AppName
    }
    catch {
        if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound) {
            if (-Not $Silent) {
                Write-Warning "IIS Site $AppName not found"
                return
            }
        }

        throw $_
    }
}
