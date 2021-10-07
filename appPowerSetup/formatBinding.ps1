function Format-Binding($binding, $AppName) {

    # Default to local site binding
    if ([string]::IsNullOrEmpty($binding)) {
        $binding = $LocalSiteBinding
    }

    $binding = $binding -replace '%s',$AppName
    $binding = $binding -replace '%d',$Env:USERDNSDOMAIN

    $rnd = Get-Random -Minimum 100 -Maximum 999
    $binding = $binding -replace '%n',$rnd

    return $binding
}
