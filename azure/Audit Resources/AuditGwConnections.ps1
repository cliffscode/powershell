$subs = Get-AzureRmSubscription
$rg = "rg"

$allResources = @()

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $resources = Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName $rg
    foreach ($resource in $resources)
    {
        $customPsObject = New-Object -TypeName PsObject
        $subscription = Get-AzureRmSubscription -SubscriptionId $resource.SubscriptionId
        $tags = $resource.Tags.Keys + $resource.Tags.Values -join ':'

        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceName -Value $resource.Name
        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $resource.ResourceGroupName
        $customPsObject | Add-Member -MemberType NoteProperty -Name Location -Value $resource.Location

        $customPsObject | Add-Member -MemberType NoteProperty -Name Type -Value $resource.ConnectionType
        $customPsObject | Add-Member -MemberType NoteProperty -Name BGP -Value $resource.EnableBgp

        $customPsObject | Add-Member -MemberType NoteProperty -Name GW1 -Value ($resource.VirtualNetworkGateway1Text -split '/')[-1]
        $customPsObject | Add-Member -MemberType NoteProperty -Name GW2 -Value ($resource.VirtualNetworkGateway2Text -split '/')[-1]

        $customPsObject | Add-Member -MemberType NoteProperty -Name LocalNetwork -Value ($resource.LocalNetworkGateway2Text -split '/')[-1]

        

        $customPsObject | Add-Member -MemberType NoteProperty -Name Tags -Value $tags
        $customPsObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $subscription.Name
        $allResources += $customPsObject

    }
       
}


$allResources | Export-Csv .\GwConnect-audit.csv -NoTypeInformation
