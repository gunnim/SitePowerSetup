##############################
#.SYNOPSIS
# Installs Windows Remote Server Administration Tools if not present
#.NOTES
# From https://blogs.technet.microsoft.com/drew/2016/12/23/installing-remote-server-admin-tools-rsat-via-powershell/
# Installation of Windows Remote Server Administration Tools may require a restart!
##############################
function Install-RsatTools {
    param (
        [switch] $Silent
    )

    # Check for RSAT tools existence
    $doesExistCmd = Get-Command New-ADServiceAccount -ErrorAction SilentlyContinue
    
    if (-Not $doesExistCmd) {
        if (-Not $Silent) {
            Write-Host 'Installation of Windows Remote Server Administration Tools may require a restart!' -foreGroundColor green
            Write-Host 'Press Enter to continue, ^C to exit' -ForeGroundColor green
            Read-Host
        }

        $web = Invoke-WebRequest https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520

        $MachineOS = (Get-WmiObject Win32_OperatingSystem).Name

        # Check for Windows Server 2012 R2
        if ($MachineOS -like "*Microsoft Windows Server*") {
            
            Add-WindowsFeature RSAT-AD-PowerShell
            return    
        }

        if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            Write-host "x64 Detected" -foregroundcolor yellow
            $Link = (($web.AllElements | Where-Object class -eq "multifile-failover-url").innerhtml[0].split(" ")|select-string href).tostring().replace("href=", "").trim('"')
        }
        else {
            Write-host "x86 Detected" -forgroundcolor yellow
            $Link = (($web.AllElements | Where-Object class -eq "multifile-failover-url").innerhtml[1].split(" ")|select-string href).tostring().replace("href=", "").trim('"')
        }

        $DLPath = ($ENV:USERPROFILE) + "\Downloads\" + ($link.split("/")[8])

        Write-Host "Downloading RSAT MSU file" -foregroundcolor yellow
        Start-BitsTransfer -Source $Link -Destination $DLPath

        $Authenticatefile = Get-AuthenticodeSignature $DLPath

        $WusaArguments = $DLPath + " /quiet"
        if ($Authenticatefile.status -ne "valid") {write-host "Can't confirm download, exiting"; break}
        Write-host "Installing RSAT for Windows 10 - please wait" -foregroundcolor yellow
        Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList $WusaArguments -Wait
    }
}
