$subs = Get-AzureRmSubscription

$allResources = @()

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $resources = Get-AzureRmNetworkSecurityGroup
    foreach ($resource in $resources)
    {
        $customPsObject = New-Object -TypeName PsObject
        $subscription = Get-AzureRmSubscription -SubscriptionId $resource.SubscriptionId
        $tags = $resource.Tags.Keys + $resource.Tags.Values -join ':'
        $nics = $resource.NetworkInterfaces
        $subnets = $resource.Subnets

        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceName -Value $resource.Name
        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $resource.ResourceGroupName
        $customPsObject | Add-Member -MemberType NoteProperty -Name Location -Value $resource.Location

        #get subnets
        $i = 0
        foreach ($subnet in $subnets)
        {
            $subnetString = ($subnet.Id -split '/')[-3] + "\" + ($subnet.Id -split '/')[-1]
            $customPsObject | Add-Member -MemberType NoteProperty -Name ("AssignedSubnet-" + $i) -Value $subnetString
            $i++
        }

        #get nics
        $i = 0
        foreach ($nic in $nics)
        {
            $nicString = ($nic.Id -split '/')[-1]
            $customPsObject | Add-Member -MemberType NoteProperty -Name ("AssignedNic-" + $i) -Value $subnetString
            $i++
        }


        $customPsObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $subscription.Name
        $allResources += $customPsObject

    }
       
}


$allResources | Export-Csv .\nsg-audit.csv -NoTypeInformation