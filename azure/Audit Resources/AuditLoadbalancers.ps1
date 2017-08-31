$subs = Get-AzureRmSubscription

$allResources = @()

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $resources = Get-AzureRmLoadBalancer
    foreach ($resource in $resources)
    {
        $customPsObject = New-Object -TypeName PsObject
        $subscription = Get-AzureRmSubscription -SubscriptionId $resource.SubscriptionId
        $tags = $resource.Tags.Keys + $resource.Tags.Values -join ':'

        # Get Private IP
        If ($resource.FrontendIpConfigurations.PrivateIpAddress -eq $null -ne $null)
        {
            $privIp = $resource.FrontendIpConfigurations.PrivateIpAddress
            
        }
        Else
        {
            $privIp = $null
        }

        #Get Public IP
        If ($resource.FrontendIpConfigurations.PublicIpAddress -ne $null)
        {
            $pubIp = (Get-AzureRmResource -ResourceId $resource.FrontendIpConfigurations.PublicIpAddress.Id).Properties.ipAddress
            
        }
        Else
        {
            $pubIp = $null
        }



        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceName -Value $resource.Name
        $customPsObject | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $resource.ResourceGroupName
        $customPsObject | Add-Member -MemberType NoteProperty -Name Location -Value $resource.Location



        $customPsObject | Add-Member -MemberType NoteProperty -Name FrontEndPrivateIp -Value $privIp
        $customPsObject | Add-Member -MemberType NoteProperty -Name FrontEndPublicIp -Value $pubIp
        
        $customPsObject | Add-Member -MemberType NoteProperty -Name BackEndPools -Value $resource.BackendAddressPools.Name

        #Get LB Rules
        $i = 0
        foreach ($lbRule in $resource.LoadBalancingRules)
        {
            $ruleString = "Name=" + $lbRule.Name + ", " + "FrontendPort=" + $lbRule.FrontendPort + ", " + "Protocol=" + $lbRule.Protocol + ", " + "BackendPort=" + $lbRule.BackendPort
            $customPsObject | Add-Member -MemberType NoteProperty -Name ("lbRule-" + $i) -Value $ruleString
            $i++
        }


        #Get Probes
        $i = 0
        foreach ($probe in $resource.Probes)
        {
            $probeString = "Name=" + $lbRule.Name + ", " + "Port=" + $probe.Port + ", " + "Protocol=" + $probe.Protocol + ", " + "Interval=" + $lbRule.IntervalInSeconds + ", " + "Count=" + $lbRule.NumberOfProbes
            $customPsObject | Add-Member -MemberType NoteProperty -Name ("probe-" + $i) -Value $probeString
            $i++
        }



        
        $customPsObject | Add-Member -MemberType NoteProperty -Name Tags -Value $tags
        $customPsObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $subscription.Name
        $allResources += $customPsObject

    }
       
}


$allResources | Export-Csv .\loadbalancer-audit.csv -NoTypeInformation