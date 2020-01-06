<#
.Synopsis
DPi30 Managed Instance Template Deployment

.Description
Function that will walk through all the required information to deploy the managed instance template
#>

$managedinstancedescription = @"
`r`nBased on your answers we suggest the Managed Instance template.
It will deploy the following to your selected Azure Subscription:
    * SQL Managed Instance (General Purpose, Gen 5 4 Cores)
    * Azure Storage Account (Blob Storage)
    * Azure Data Factory
    * Virtual Machine Jump Box (B2ms, with SSMS and Self Hosted Integration Runtime)
    * Virtual Network to support the Managed Instance
"@

function DeployManagedInstanceTemplate {
    # Function to gather information and deploy the Managed Instance Template
    Param(
        # The resource group name that the template will be deployed to
        $ResourceGroupName,
        # The data factory region determined by the Geography chosen 
        $DataFactoryRegion
    )
    
    Write-Host "`r`nNow let's get the Managed Instance template deployed, just a few questions and we can get this kicked off."
    $dbservername = Read-Host "What would you like to name the Database Server?"
    $valid = DatabaseServerNameValidation -Name $dbservername
    while(!($valid.Result)){
        # Validation loop (Keep trying until you get the name right)
        Write-Host $valid.Message -ForegroundColor Red
        $dbservername = Read-Host "What would you like to name the Database Server?"
        $valid = DatabaseServerNameValidation -Name $dbservername
    }

    $dbadminlogin = Read-Host "What username would you like to use for the Database Server?"
    $valid = DatabaseLoginNameValidation -Name $dbadminlogin
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $dbadminlogin = Read-Host "What username would you like to use for the Database Server?"
        $valid = DatabaseLoginNameValidation -Name $dbadminlogin
    }

    $dbadminpassword = Read-Host "Password" -AsSecureString

    $storagename = Read-Host "What would you like to name the Blob storage account?"
    $valid = StorageAccountNameValidation -Name $storagename
    while(!($valid.Result)){ 
        Write-Host $valid.Message -ForegroundColor Red
        $storagename = Read-Host "What would you like to name the Blob storage account?"
        $valid = StorageAccountNameValidation -Name $storagename
    }

    $dfname = Read-Host "What would you like to name the Data Factory?"
    $valid = DataFactoryNameValidation -Name $dfname 
    while(!($valid.Result)){ 
        Write-Host $valid.Message -ForegroundColor Red
        $dfname = Read-Host "What would you like to name the Data Factory?"
        $valid = DataFactoryNameValidation -Name $dfname 
    }

    $jumpboxname = Read-Host "What would you like to name the Jump Box Virtual Machine?"
    $valid = VMNameValidation -Name $jumpboxname 
    while(!($valid.Result)){ 
        Write-Host $valid.Message -ForegroundColor Red
        $jumpboxname = Read-Host "What would you like to name the Jump Box Virtual Machine?"
        $valid = VMNameValidation -Name $jumpboxname 
    }

    $vmadminlogin = Read-Host "What username would you like to use for the Virtual Machine?"
    $valid = DatabaseLoginNameValidation -Name $vmadminlogin
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $vmadminlogin = Read-Host "What username would you like to use for the Virtual Machine?"
        $valid = DatabaseLoginNameValidation -Name $vmadminlogin
    }

    $vmadminpassword = Read-Host "Password" -AsSecureString

    $vmdnsprefix = Read-Host "What DNS Prefix (beginning of the host name) would you like to use for the Virtual Machine?"
    $valid = DNSPrefixValidation -Name $vmdnsprefix
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $vmdnsprefix = Read-Host "What DNS Prefix (beginning of the host name) would you like to use for the Virtual Machine?"
        $valid = DNSPrefixValidation -Name $vmdnsprefix
    }

    $vnetname = Read-Host "What name would you like to use for the Virtual Network?"
    $valid = vNetNameValidation -Name $vnetname
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $vnetname = Read-Host "What name would you like to use for the Virtual Network?"
        $valid = vNetNameValidation -Name $vnetname
    }

    $vnetaddressrange = Read-Host "What address range would you like to use for the Virtual Network? (ex. 10.0.0.0/16)"
    $valid = CIDRValidation -Name $vnetaddressrange
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $vnetaddressrange = Read-Host "What address range would you like to use for the Virtual Network? (ex. 10.0.0.0/16)"
        $valid = CIDRValidation -Name $vnetaddressrange
    }

    $vmsubnetname = Read-Host "What subnet name would you like to use for the Virtual Machine?"
    $valid = AzureNetworkingNameValidation -Name $vmsubnetname
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $vmsubnetname = Read-Host "What subnet name would you like to use for the Virtual Machine?"
        $valid = AzureNetworkingNameValidation -Name $vmsubnetname
    }

    $vmsubnetaddressrange = Read-Host "What address range would you like to use for the Virtual Machine Subnet? (Must be included in the Virtual Network Subnet range of $vnetaddressrange)"
    $valid = CIDRValidation -Name $vmsubnetaddressrange
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $vmsubnetaddressrange = Read-Host "What address range would you like to use for the Virtual Machine Subnet? (Must be included in the Virtual Network Subnet range of $vnetaddressrange)"
        $valid = CIDRValidation -Name $vmsubnetaddressrange
    }

    $misubnetname = Read-Host "What subnet name would you like to use for the Managed Instance?"
    $valid = AzureNetworkingNameValidation -Name $misubnetname
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $misubnetname = Read-Host "What subnet name would you like to use for the Managed Instance?"
        $valid = AzureNetworkingNameValidation -Name $misubnetname
    }

    $misubnetaddressrange = Read-Host "What address range would you like to use for the Managed Instance Subnet? (Must be included in the Virtual Network Subnet range of $vnetaddressrange)"
    $valid = CIDRValidation -Name $misubnetaddressrange
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $misubnetaddressrange = Read-Host "What address range would you like to use for the Managed Instance Subnet? (Must be included in the Virtual Network Subnet range of $vnetaddressrange)"
        $valid = CIDRValidation -Name $misubnetaddressrange
    }
    
    Write-Host "Ok! That's everything, the deployment will take up to 3 hours, to confirm:"
    $confirmtext = @"

    Resource Group Name:             $ResourceGroupName
    Managed Instance Server Name:    $dbservername
    Managed Instance Server Login:   $dbadminlogin
    Blob Storage Account Name:       $storagename
    Data Factory Name:               $dfname
    Jumpbox VM Name:                 $jumpboxname
    Jumpbox Admin Login:             $vmadminlogin
    Jumpbox DNS Prefix:              $vmdnsprefix
    Virtual Network Name:            $vnetname
    Virtual Network Address Range:   $vnetaddressrange
    Virtual Network Subnet Name:     $vmsubnetname
    VM Subnet Range:                 $vmsubnetaddressrange
    Managed Instance Subnet Name:    $misubnetname
    Managed Instance Subnet Range:   $misubnetaddressrange

    To re-run in case of failure you can use:
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"$PSScriptRoot/../managedinstance/dpi30managedinstance.json`" -managedInstanceName `"$dbservername`" -managedInstanceAdminLogin `"$dbadminlogin`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname`" -dataFactoryRegion `"$DataFactoryRegion`" -jumpboxName `"$jumpboxname`" -jumpboxAdminUsername `"$vmadminlogin`" -jumpboxDnsLabelPrefix `"$vmdnsprefix`" -virtualNetworkName `"$vnetname`" -virtualNetworkAddressPrefix `"$vnetaddressrange`" -defaultSubnetName `"$vmsubnetname`" -defaultSubnetPrefix `"$vmsubnetaddressrange`" -managedInstanceSubnetName `"$misubnetname`" -managedInstanceSubnetPrefix `"$misubnetaddressrange`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot/../managedinstance/dpi30managedinstance.json" -managedInstanceName $dbservername -managedInstanceAdminLogin $dbadminlogin -managedInstanceAdminPassword $dbadminpassword -storageAccountName $storagename -dataFactoryName $dfname -dataFactoryRegion $DataFactoryRegion -jumpboxName $jumpboxname -jumpboxAdminUsername $vmadminlogin -jumpboxAdminPassword $vmadminpassword -jumpboxDnsLabelPrefix $vmdnsprefix -virtualNetworkName $vnetname -virtualNetworkAddressPrefix $vnetaddressrange -defaultSubnetName $vmsubnetname -defaultSubnetPrefix $vmsubnetaddressrange -managedInstanceSubnetName $misubnetname -managedInstanceSubnetPrefix $misubnetaddressrange
    }
}