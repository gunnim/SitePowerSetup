##############################
#.SYNOPSIS
# Installs Windows Remote Server Administration Tools if not present
#.NOTES
# From https://blogs.technet.microsoft.com/drew/2016/12/23/installing-remote-server-admin-tools-rsat-via-powershell/
# Installation of Windows Remote Server Administration Tools may require a restart!
#.LINK
# https://blogs.technet.microsoft.com/drew/2016/12/23/installing-remote-server-admin-tools-rsat-via-powershell/
##############################
function Install-RsatTools {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param()
    
    # Check for RSAT tools existence
    $doesExistCmd = Get-Command New-ADServiceAccount -ErrorAction SilentlyContinue
    
    if (-Not $doesExistCmd) {
        if ($PSCmdlet.ShouldProcess("Installation of Windows Remote Server Administration Tools may require a restart, would you like to continue?")) {
            $web = Invoke-WebRequest https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520

            $MachineOS = (Get-CimInstance Win32_OperatingSystem).Name
    
            # Check for Windows Server 2012 R2
            if ($MachineOS -like "*Microsoft Windows Server*") {
                
                Add-WindowsFeature RSAT-AD-PowerShell
                return    
            }
    
            if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
                Write-Verbose "x64 Detected"
                $Link = (($web.AllElements | Where-Object class -eq "multifile-failover-url").innerhtml[0].split(" ")|select-string href).tostring().replace("href=", "").trim('"')
            }
            else {
                Write-Verbose "x86 Detected"
                $Link = (($web.AllElements | 
                    Where-Object class -eq "multifile-failover-url").innerhtml[1].split(" ") | 
                    select-string href).tostring().replace("href=", "").trim('"')
            }
    
            $DLPath = ($ENV:USERPROFILE) + "\Downloads\" + ($link.split("/")[8])
    
            Write-Verbose "Downloading RSAT MSU file"
            Start-BitsTransfer -Source $Link -Destination $DLPath
    
            $Authenticatefile = Get-AuthenticodeSignature $DLPath
    
            $WusaArguments = $DLPath + " /quiet"
            if ($Authenticatefile.status -ne "valid") {
                Write-Verbose "Can't confirm download, exiting"
                break
            }
            Write-Verbose "Installing RSAT for Windows 10 - please wait"
            Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList $WusaArguments -Wait
        }
    }
}
