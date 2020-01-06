<#
.Synopsis
DPi30 Deploy Modern Data Warehouse

.Description
Function that will walk through all the required information to deploy the modern data warehouse template
#>

$datawarehousedescription = @"
`r`nBased on your answers we suggest the Modern Data Warehouse template.
It will deploy the following to your selected Azure Subscription:
    * Azure Data Factory
    * Azure Data Lake Gen 2
    * Azure Databricks
    * Azure Synapse Analytics (formerly Azure Data Warehouse)
"@

function DeployDWTemplate {
    # Function to gather information and deploy the Modern Data Warehouse Template
    Param(
        # The resource group name that the template will be deployed to
        $ResourceGroupName,
        # The data factory region determined by the Geography chosen 
        $DataFactoryRegion
    )
   
    Write-Host "`r`nNow let's get the Modern Data Warehouse template deployed, just a few questions and we can get this kicked off."
    
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
    
    $dwname = Read-Host "What would you like to name the Data Warehouse?"
    $valid = DatabaseNameValidation -Name $dwname
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $dwname = Read-Host "What would you like to name the Data Warehouse?"
        $valid = DatabaseNameValidation -Name $dwname
    }

    $databricksname = Read-Host "What would you like to name the Databricks Workspace?"
    $valid = DatabricksNameValidation -Name $databricksname
    while(!($valid.Result)){
        Write-Host $valid.Message -ForegroundColor Red
        $databricksname = Read-Host "What would you like to name the Databricks Workspace?"
        $valid = DatabricksNameValidation -Name $databricksname
    }

    $storagename = Read-Host "What would you like to name the Data Lake storage account?"
    $valid = StorageAccountNameValidation -Name $storagename
    while(!($valid.Result)){ 
        Write-Host $valid.Message -ForegroundColor Red
        $storagename = Read-Host "What would you like to name the Data Lake storage account?"
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
    Datawarehouse Server Name:       $dbservername
    Datawarehouse Server Login:      $dbadminlogin
    Datawarehouse Name:              $dwname
    Databricks Workspace Name:       $databricksname
    Data Lake Storage Account Name:  $storagename
    Data Factory Name:               $dfname

    To re-run in case of failure you can use:
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"$PSScriptRoot/../moderndatawarehouse/dpi30moderndatawarehouse.json`" -azureSqlServerName `"$dbservername`" -azureSqlServerAdminLogin `"$dbadminlogin`" -azureSqlDataWarehouseName `"$dwname`" -databricksWorkspaceName `"$databricksname`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname`" -dataFactoryRegion `"$DataFactoryRegion`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot/../moderndatawarehouse/dpi30moderndatawarehouse.json" -azureSqlServerName $dbservername -azureSqlServerAdminLogin $dbadminlogin -azureSqlServerAdminPassword $dbadminpassword -azureSqlDataWarehouseName $dwname -databricksWorkspaceName $databricksname -storageAccountName $storagename -dataFactoryName $dfname -dataFactoryRegion $DataFactoryRegion
    }
}