Function Get-Folder {
    $null = [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"
    $foldername.Description = "Choose IIS site directory"

    if($foldername.ShowDialog() -eq "OK")
    {
        return $foldername.SelectedPath
    }
}
