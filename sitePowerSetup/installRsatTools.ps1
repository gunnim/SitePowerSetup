##############################
#.SYNOPSIS
# Installs Windows Remote Server Administration Tools if not present
# Assumes a 64bit system
#.NOTES
# Installation of Windows Remote Server Administration Tools may require a restart!
#.LINK
##############################
function Install-RsatTools {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param()
    
    # Check for RSAT tools existence
    $doesExistCmd = Get-Command New-ADServiceAccount -ErrorAction SilentlyContinue
    
    if (-Not $doesExistCmd) {
        if ($PSCmdlet.ShouldProcess("Installation of Windows Remote Server Administration Tools may require a restart, would you like to continue?")) {

            $MachineOS = (Get-CimInstance Win32_OperatingSystem).Name
    
            # Check for Windows Server 2012 R2
            if ($MachineOS -like "*Microsoft Windows Server*") {
                
                Add-WindowsFeature RSAT-AD-PowerShell
                return    
            }

            # $WusaArguments = $DLPath + " /quiet"

            Write-Verbose "Installing RSAT for Windows 10 - please wait"
            Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList $RSATFilePath -Wait
        }
        else {
            break
        }
    }
}
