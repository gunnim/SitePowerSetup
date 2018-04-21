Function Get-Folder($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"
    $foldername.Description = "Choose IIS site directory"

    if($foldername.ShowDialog() -eq "OK")
    {
        return $foldername.SelectedPath
    }
    return $null
}
