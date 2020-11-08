Function Get-Folder {
    $null = [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    Write-Host "Spawning site directory dialog, please use alt-tab to find it if not visible"
    
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"
    $foldername.Description = "Choose local IIS site directory"

    if($foldername.ShowDialog() -eq "OK")
    {
        return $foldername.SelectedPath
    }
}
