$subs = Get-AzureRmSubscription

$allResources = @()

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $vnetSub = Get-AzureRmVirtualNetwork
    foreach ($vnet in $vnetSub)
    {
        $customVnetObject = New-Object -TypeName PsObject

        $customVnetObject | Add-Member -MemberType NoteProperty -Name VnetName -Value $vnet.Name
        $customVnetObject | Add-Member -MemberType NoteProperty -Name Location -Value $vnet.Location
        $customVnetObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $sub.Name


        $i = 0
        foreach ($prefix in $vnet.AddressSpace)
        {
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("AddressSpace-" + $i) -Value $vnet.AddressSpace[$i].AddressPrefixes[0]
            $i++
        }

        $i = 0
        foreach ($subnet in $vnet.Subnets)
        {
            $subnetString = $subnet.Name + ":" + $vnet.Subnets[$i].AddressPrefix
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("Subnet-" + $i) -Value $subnetString
            $i++
        }

        $i = 0
        foreach ($peering in $vnet.virtualNetworkPeerings)
        {
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i) -Value $vnet.VirtualNetworkPeerings[$i].Name
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i + "-(State)") -Value $vnet.VirtualNetworkPeerings[$i].PeeringState
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i + "-(RemoteVirtualNetwork)") -Value ($vnet.VirtualNetworkPeerings[$i].RemoteVirtualNetwork.Id -split '/')[-1]
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i + "-(AllowVnetAccecss)") -Value $vnet.VirtualNetworkPeerings[$i].AllowVirtualNetworkAccess
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i + "-(AllowForwardedTraffic)") -Value $vnet.VirtualNetworkPeerings[$i].AllowForwardedTraffic
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i + "-(AllowGatewayTransit)") -Value $vnet.VirtualNetworkPeerings[$i].AllowGatewayTransit
            $customVnetObject | Add-Member -MemberType NoteProperty -Name ("VNetPeering" + $i + "-(UseRemoteGateway)") -Value $vnet.VirtualNetworkPeerings[$i].UseRemoteGateways
            $i++
        }
        
        $allResources += $customVnetObject
    }
}

$allResources | Export-Csv .\vnet-audit.csv -NoTypeInformation