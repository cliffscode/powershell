#verbose
$oldverbose = $VerbosePreference
$VerbosePreference = 'continue'

#paramters
$vmName = 'vm1'
$vmResourceGroup = 'rg1'
$backupStorageAccount = 'storageaccount'
$backupResourceGroup = 'rg1'
$backupContainer = 'vmbackup'
$localFilePath = 'C:\VM Backup'

#get VM
$vm = Get-AzureRmVM -ResourceGroupName $vmResourceGroup -Name $vmName

#ensure backup container exists
$destinationKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $backupResourceGroup -Name $backupStorageAccount -ErrorAction SilentlyContinue
$destContext = New-AzureStorageContext -StorageAccountName $backupStorageAccount -StorageAccountKey $destinationKeys[1].Value

if (!$(Get-AzureStorageContainer -Context $destContext -Name $backupContainer -ErrorAction SilentlyContinue)){
    Write-Verbose 'Storage Account container does not exist....creating'
    New-AzureStorageContainer -Context $destContext -Name $backupContainer -InformationAction SilentlyContinue
}
else {
    Write-Verbose 'Storage Account container already exists'
}

#shutdown VM
Write-Verbose "Shutting down Virtual Machine $vmName in Resource Group $vmResourceGroup"
$vm | Stop-AzureRmVM -StayProvisioned -Force -InformationAction SilentlyContinue

#copy OS disk to backup container
$vmOsDiskUri = $vm.StorageProfile.OsDisk.Vhd.Uri
$vmOsDiskStorageAccount = ([System.Uri]$vmOsDiskUri).Host.Split('.')[0]
$vmOsDiskContainer = ([System.Uri]$vmOsDiskUri).Segments[-2] -replace '/'
$vmOsBlob = ([System.Uri]$vmOsDiskUri).Segments[-1]
$vmOsSourceKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $vmResourceGroup -Name $vmOsDiskStorageAccount
$vmSourceContext = New-AzureStorageContext -StorageAccountName $vmOsDiskStorageAccount -StorageAccountKey $vmOsSourceKeys[1].value

Write-Verbose "Performing blob copy of OS Disk $vmOsBlob"
Start-AzureStorageBlobCopy -SrcBlob $vmOsBlob -SrcContainer $vmOSDiskContainer -Context $vmSourceContext -DestContainer $backupContainer -DestBlob $vmOsBlob -DestContext $destContext -Force | `
    Get-AzureStorageBlobCopyState -WaitForComplete

#copy data disks
$dataDisks = $vm.StorageProfile.DataDisks

foreach ($dataDisk in $dataDisks) {
    $vmDataDiskUri = $dataDisk.StorageProfile.OsDisk.Vhd.Uri
    $vmDataDiskSourceStorageAccount = ([System.Uri]$vmDataDiskUri).Host.Split('.')[0]
    $vmDataDiskSourceContainer = ([System.Uri]$vmDataDiskUri).Segments[-2] -replace '/'
    $vmDataDiskBlob = ([System.Uri]$vmDataDiskUri).Segments[-1]
    $vmDataDiskStorageKey = Get-AzureRmStorageAccountKey -ResourceGroupName $vmResourceGroup -Name $vmDataDiskSourceStorageAccount
    $vmdataDiskContext = New-AzureStorageContext -StorageAccountName $vmDataDiskSourceStorageAccount -StorageAccountKey $vmDataDiskStorageKey[1].Value
    
    Write-Verbose "Copying osDisk $vmDataDiskBlob to $($destContext.storageAccount.BlobEndPoint.AbsoluteUri)$($backupContainer)"
    Start-AzureStorageBlobCopy -SrcBlob $vmDataDiskBlob -SrcContainer $vmDataDiskSourceContainer -Context $vmdataDiskContext -DestContainer $backupContainer -DestBlob $vmDataDiskBlob -DestContext $destContext -Force | `
         Get-AzureStorageBlobCopyState -WaitForComplete
}


#export VM config, and upload to backup container
Write-Verbose "Exporting VM config to $localFilePath\$vmName.json"
$vm | ConvertTo-Json -Depth 100 | Out-File -FilePath "$localFilePath\$vmName.json" -Encoding ascii -Force

Write-Verbose "Uploading VM config $vmName.json to $($destContext.storageAccount.BlobEndPoint.AbsoluteUri)$($backupContainer)"
Set-AzureStorageBlobContent -File "$localFilePath\$vmName.json" -Container $backupContainer -Blob $vmName.json -Context $destContext -InformationAction SilentlyContinue

#start Vm
Write-Verbose "Backup complete, starting Virtual Machine $vmName in Resource Group $vmResourceGroup"
Start-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -InformationAction SilentlyContinue

#set back verbose preference

$VerbosePreference = $oldverbose