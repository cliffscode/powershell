$nsgs = Get-AzureRmNetworkSecurityGroup
$exportPath = 'C:\temp'

Foreach ($nsg in $nsgs) {
    $nsgRules = $nsg.SecurityRules
    foreach ($nsgRule in $nsgRules) {
        $nsgRule | Select-Object Name,Description,Priority,SourceAddressPrefix,SourcePortRange,DestinationAddressPrefix,DestinationPortRange,Protocol,Access,Direction `
        | Export-Csv "$exportPath\$($nsg.Name).csv" -NoTypeInformation -Encoding ASCII -Append
    }
}