$subs = Get-AzureRmSubscription

$allResources = @()

foreach ($sub in $subs) 
{
    Select-AzureRmSubscription -SubscriptionId $sub.Id
    $vmSub = Get-AzureRmVM
    foreach ($vm in $vmSub)
    {
        $customVmObject = New-Object -TypeName PsObject
        
        If ($vm.StorageProfile.OsDisk.ManagedDisk.Id -ne $null)
        {
            $osDiskStorageAccount = 'Managed Disk'
        }
        
        else
        {
            $osDiskStorageAccount = ([uri]$vm.StorageProfile.OsDisk.Vhd.Uri).Host
        }
        
        $nics = $vm.NetworkProfile.NetworkInterfaces
        $dataDiskS = $vm.StorageProfile.DataDisks
        $subscription = Get-AzureRmSubscription -SubscriptionId ($vm.Id -split '/')[2]
        
        $customVmObject | Add-Member -MemberType NoteProperty -Name VmName -Value $vm.Name
        $customVmObject | Add-Member -MemberType NoteProperty -Name RG -Value $vm.ResourceGroupName
        $customVmObject | Add-Member -MemberType NoteProperty -Name Location -Value $vm.Location
        $customVmObject | Add-Member -MemberType NoteProperty -Name Size -Value $vm.HardwareProfile.VmSize

        $i = 0
        foreach ($adapter in $nics)
        {
            $nic = Get-AzureRmResource -ResourceId $adapter.Id
            $vnet = ($nic.Properties.ipConfigurations.properties.subnet -split '/')[-3]
            $subnet = ($nic.Properties.ipConfigurations.properties.subnet -split '/')[-1]
            $privateIpAddress = $nic.Properties.ipConfigurations.properties.privateIPAddress
            $publicIpId = $nic.Properties.ipConfigurations.properties.publicIPAddress.id
            
            if ($publicIpId -eq $null)
            {
                $publicIpAddress = $null
            }
            Else
            {
                $publicIpResource = Get-AzureRmResource -ResourceId $publicIpId -ErrorAction SilentlyContinue
                $publicIpAddress = $publicIpResource.Properties.ipAddress
            }
            
            $availabilitySet = ($vm.AvailabilitySetReference.Id -split '/')[-1]        
            $customVmObject | Add-Member -MemberType NoteProperty -Name ("nic-" + $i + "-Vnet") -Value $vnet
            $customVmObject | Add-Member -MemberType NoteProperty -Name ("nic-" + $i + "-Subnet")  -Value $subnet
            $customVmObject | Add-Member -MemberType NoteProperty -Name ("nic-" + $i + "-PrivateIpAddress") -Value $privateIpAddress
            $customVmObject | Add-Member -MemberType NoteProperty -Name ("nic-" + $i + "-PublicIpAddress") -Value $publicIpAddress
            $i++
        }

        $customVmObject | Add-Member -MemberType NoteProperty -Name AvailabilitySet -Value $availabilitySet
        $customVmObject | Add-Member -MemberType NoteProperty -Name osDisk -Value $osDiskStorageAccount

        $i = 0
        foreach ($dataDisk in $dataDiskS)
        {
            if ($DataDisk.ManagedDisk.Id -ne $null)
            {
                $dataDiskHost = 'Managed Disk'
            }
            Else
            {
                $dataDiskHost = ([uri]($dataDisk.Vhd.Uri)).Host
            }
            $customVmObject | Add-Member -MemberType NoteProperty -Name ("dataDisk-" + $i) -Value $dataDiskHost
            $i++
        }
        
        $customVmObject | Add-Member -MemberType NoteProperty -Name Subscription -Value $subscription.Name
        $allResources += $customVmObject
    }
}

$allResources | Export-Csv .\vm-audit.csv -NoTypeInformation


