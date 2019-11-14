$subs = Get-AzureRmSubscription <# gets the subscription ID, subscription name, and home tenant for subscriptions that the current account can access #>

$allResources = @() <# Array SubExpression operator - allResources as an array #>

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $resources = Get-AzureRmResource
    foreach ($resource in $resources)
    {
        $customPsObject = New-Object -TypeName PsObject
        $subscription = Get-AzureRmSubscription -SubscriptionId $resource.SubscriptionId
        $tags = $resource.Tags.Keys + $resource.Tags.Values -join ':'

        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceName -Value $resource.Name
        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $resource.ResourceGroupName
        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceType -Value $resource.ResourceType
        $customPsObject | Add-Member -MemberType NoteProperty -Name Kind -Value $resource.Kind
        $customPsObject | Add-Member -MemberType NoteProperty -Name Location -Value $resource.Location
        $customPsObject | Add-Member -MemberType NoteProperty -Name Tags -Value $tags
        $customPsObject | Add-Member -MemberType NoteProperty -Name Sku -Value $resource.Sku
        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceId -Value $resource.ResourceId
        $customPsObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $subscription.Name
        $allResources += $customPsObject <# Appends customPsObject to the allResources array #>

    }
       
}


$allResources | Export-Csv .\resource-audit.csv -NoTypeInformation
