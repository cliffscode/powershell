$subs = Get-AzureRmSubscription

$allResources = @()

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $vmSub = Get-AzureRmVM
    foreach ($vm in $vmSub)
    {
        $customVmObject = New-Object -TypeName PsObject
        $nic = Get-AzureRmResource -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
        $vnet = ($nic.Properties.ipConfigurations.properties.subnet -split '/')[-3]
        $subnet = ($nic.Properties.ipConfigurations.properties.subnet -split '/')[-1]
        $subscription = Get-AzureRmSubscription -SubscriptionId ($vm.Id -split '/')[2]
        $ipAddress = $nic.Properties.ipConfigurations.properties.privateIPAddress
        $availabilitySet = ($vm.AvailabilitySetReference.Id -split '/')[-1]
        $osDiskStorageAccount = ([uri]$vm.StorageProfile.OsDisk.Vhd.Uri).Host
        $dataDiskStorageAccount = ([uri]($vm.StorageProfile.DataDisks[0].Vhd.Uri)).Host
        $customVmObject | Add-Member -MemberType NoteProperty -Name VmName -Value $vm.Name
        $customVmObject | Add-Member -MemberType NoteProperty -Name Location -Value $vm.Location
        $customVmObject | Add-Member -MemberType NoteProperty -Name Size -Value $vm.HardwareProfile.VmSize
        $customVmObject | Add-Member -MemberType NoteProperty -Name Vnet -Value $vnet
        $customVmObject | Add-Member -MemberType NoteProperty -Name Subnet -Value $subnet
        $customVmObject | Add-Member -MemberType NoteProperty -Name IpAddress -Value $ipAddress
        $customVmObject | Add-Member -MemberType NoteProperty -Name AvailabilitySet -Value $availabilitySet
        $customVmObject | Add-Member -MemberType NoteProperty -Name osDiskStorageAccount -Value $osDiskStorageAccount
        $customVmObject | Add-Member -MemberType NoteProperty -Name dataDiskStorageAccount -Value $dataDiskStorageAccount
        $customVmObject | Add-Member -MemberType NoteProperty -Name RG -Value $vm.ResourceGroupName
        $customVmObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $subscription.Name
 
        $allResources += $customVmObject
    }
}

$allResources | Export-Csv .\vm-audit.csv -NoTypeInformation