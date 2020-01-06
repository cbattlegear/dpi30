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
    # Function to gather information and deploy the Simple Template
    Param(
        # The resource group name that the template will be deployed to
        $ResourceGroupName,
        # The data factory region determined by the Geography chosen 
        $DataFactoryRegion
    )
    
    Write-Host "`r`nNow let's get the Simple template deployed, just a few questions and we can get this kicked off."
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

    $dbname = Read-Host "What would you like to name the Database?"
    $valid = DatabaseNameValidation -Name $dbname
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $dbname = Read-Host "What would you like to name the Database?"
        $valid = DatabaseNameValidation -Name $dbname
    }

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
    
    Write-Host "Ok! That's everything, the deployment will take a few minutes, to confirm:"
    $confirmtext = @"

    Resource Group Name:             $ResourceGroupName
    Database Server Name:            $dbservername
    Database Server Login:           $dbadminlogin
    Database Name:                   $dwname
    Blob Storage Account Name:       $storagename
    Data Factory Name:               $dfname

    To re-run in case of failure you can use:
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"$PSScriptRoot/simple/dpi30simple.json`" -azureSqlServerName `"$dbservername`" -azureSqlServerAdminLogin `"$dbadminlogin`" -azureSqlDatabaseName `"$dbname`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname` -dataFactoryRegion `"$DataFactoryRegion`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot/simple/dpi30simple.json" -azureSqlServerName $dbservername -azureSqlServerAdminLogin $dbadminlogin -azureSqlServerAdminPassword $dbadminpassword -azureSqlDataWarehouseName $dbname -storageAccountName $storagename -dataFactoryName $dfname -dataFactoryRegion $DataFactoryRegion
    }
}