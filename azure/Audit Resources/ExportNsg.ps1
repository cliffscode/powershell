$nsgs = Get-AzureRmNetworkSecurityGroup
$exportPath = 'C:\temp'

Foreach ($nsg in $nsgs) {
    $nsgRules = $nsg.SecurityRules
    foreach ($nsgRule in $nsgRules) {
        $nsgRule | Select-Object Name,Description,Priority,@{Name=’SourceAddressPrefix’;Expression={[string]::join(“,”, ($_.SourceAddressPrefix))}},@{Name=’SourcePortRange’;Expression={[string]::join(“,”, ($_.SourcePortRange))}},@{Name=’DestinationAddressPrefix’;Expression={[string]::join(“,”, ($_.DestinationAddressPrefix))}},@{Name=’DestinationPortRange’;Expression={[string]::join(“,”, ($_.DestinationPortRange))}},Protocol,Access,Direction `
        | Export-Csv "$exportPath\$($nsg.Name).csv" -NoTypeInformation -Encoding ASCII -append
    }
}
