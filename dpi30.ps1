<#
.Synopsis
DPi30 Decision and Deployment Tree

.Description
Script that will walk you through determining the proper DPi30 Template and help you deploy it step by step.
#>

### Validation Functions ###
function ResourceGroupNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Resource Group name restrictions: alphanumeric characters, periods, underscores, hyphens and parenthesis and cannot end in a period, less than 90 characters
    if ($Name -cmatch "^[\w\-\.\(\)]{1,90}[^\.]$"){
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Resource Group name restrictions: alphanumeric characters, periods, underscores, hyphens and parenthesis and cannot end in a period, less than 90 characters"}
    }
}

function StorageAccountNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Storage Account name restrictions: Lower case leters or numbers, 3 to 24 characters
    if ($Name -cmatch "^[a-z0-9]{3,24}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Storage Account name restrictions: Lower case leters or numbers, 3 to 24 characters"}
    }
}

function DatabricksNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Databricks name restrictions: Alphanumeric characters, underscores, and hyphens are allowed, and the name must be 1-30 characters long.
    if ($Name -cmatch "^[\w-]{1,30}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Databricks name restrictions: Alphanumeric characters, underscores, and hyphens are allowed, and the name must be 1-30 characters long."}
    }
}

function DatabaseNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Database name restrictions: Alphanumeric characters, underscores 1-128 characters long.
    if ($Name -cmatch "^[\w]{1,128}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Database name restrictions: Alphanumeric characters, underscores 1-128 characters long."}
    }
}

function DatabaseServerNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Database Server name restrictions: Your server name can contain only lowercase letters, numbers, and '-', but can't start or end with '-' or have more than 63 characters.
    if ($Name -cmatch "^[^-][a-z0-9-]{1,63}(?<!-)$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Database Server name restrictions: Your server name can contain only lowercase letters, numbers, and '-', but can't start or end with '-' or have more than 63 characters."}
    }
}

function DatabaseLoginNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Database Login name restrictions: Your login name must not include non-alphanumeric characters and must not start with numbers or symbols
    if ($Name -cmatch "^[^0-9][a-zA-Z0-9]{1,128}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Database Login name restrictions: Your login name must not include non-alphanumeric characters and must not start with numbers or symbols"}
    }
}

function DataFactoryNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Data Factory name restrictions: contain only letters, numbers and hyphens. The first and last characters must be a letter or number.
    if ($Name -cmatch "^[^-][a-zA-Z0-9]{1,128}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Data Factory name restrictions: contain only letters, numbers and hyphens. The first and last characters must be a letter or number."}
    }
}

### End Validation Functions ###

function DetermineTemplate {
    # Questionaire to determine best fit, Current logic is if you answer yes at least twice you should use Modern Data Warehouse
    $dwscore = 0
    Clear-Host
    Write-Host "`r`nLet's determine the best deployment for your situation, Please answer the next few questions with y (yes) or n (no)."

    $confirmation = Read-Host "`r`nWill you have more than 1 TB of data? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "`r`nDo you have a highly analytics-based workload? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "`r`nDo you want to utilize any real-time or streaming data? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "`r`nWould you like to integrate machine learning into your business intelligence? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "`r`nDo you have Python, Scala, R, or Spark experience? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    if ($dwscore -ge 2) {
        return $true
    } else {
        return $false
    }
}

function DeployResourceGroup {
    # Function to gather information and deploy the resource group
    # TODO: Determine best way to have input while it is gathering Region Data
    Clear-Host
    # Gathers all US based regions that can deploy SQL and Databricks
    # TODO: Determine best way to allow this to be international
    
    Write-Host "`r`nFirst, let's create a Resource Group to put all these services in."
    $ResourceGroupName = Read-Host "What would you like the Resource Group named"
    $valid = ResourceGroupNameValidation -Name $ResourceGroupName
    while(!($valid.Result)) {
        Write-Host $valid.Message -ForegroundColor Red
        $ResourceGroupName = Read-Host "`r`nWhat would you like the Resource Group named"
        $valid = ResourceGroupNameValidation -Name $ResourceGroupName
    }
    $ExistingResourceGroup = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
    if($notPresent) {
        #Creating lists of geography and default data factory regions for those geographies
        $regionfilter = ""
        $datafactoryregion = ""
        $geographylist = [ordered]@{
            [int]"1" = "US"
            [int]"2" = "Europe"
            [int]"3" = "Asia"
        }
        $datafactoryregions = @{
            "US" = "East US"
            "Europe" = "NorthEurope"
            "Asia" = "Southeast Asia"
        }
        #Prompting for geography selection, result will select default Data Factory region and list regions for that geography
        Write-Host "`r`nWhich geography would you like to deploy in?`r`n"
        $geographylist.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key))" "$($_.Value)"}
        $geographyselection = Read-Host "`r`nGeography Number"
        $datafactoryregion = $datafactoryregions[$geographylist.[int]$geographyselection]
        #Write-Host "Selected $($geographyselection) which is $($geographylist.[int]$geographyselection) and our Data Factory region is $($datafactoryregion)"
        
        #Prompting for region selection.
        $rawlocationlist= ((Get-AzLocation | Where-Object Providers -like "Microsoft.Databricks" | Where-Object Providers -like "Microsoft.Sql" | Where-Object DisplayName -like "*$($geographylist.[int]$geographyselection)*").DisplayName)
        Write-Host "`r`nHere are the regions available for deployment:`r`n"
        $locationlist = [ordered] @{}

        for($i=0;$i -le $locationlist.Length;$i++)
        {
            $locationlist.Add($i + 1, $rawlocationlist[$i])
        }
        $locationlist.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key))" "$($_.Value)"}
        $rglocation = Read-Host "`r`nRegion Number"
        $rglocation = $locationlist.[int]$rglocation
        #Got our Region for resource group deployment
        # Assign to prevent object being returned in function
        $resourcegroupreturnhold = New-AzResourceGroup -Name $ResourceGroupName -Location $rglocation -Tag @{dpi30="True"}
        Write-Host "`r`nYour new Resource Group '$($ResourceGroupName)' has been deployed to $($rglocation)" -ForegroundColor Green
        $resourceGroupInformation = @{ResourceGroupName = $ResourceGroupName; DataFactoryRegion = $datafactoryregion}
        return $resourceGroupInformation
    } else {
        Write-Host "That resource group already exists in $($ExistingResourceGroup.Location)"
        $confirmation = Read-Host "Would you like to use the existing Resource Group? (y/n)"
        if ($confirmation -eq 'y') {
            # Default to East US when we don't know (to lazy to determine) the geography            
            $datafactoryregion = "East US"
            $resourceGroupInformation = @{ResourceGroupName = $ResourceGroupName; DataFactoryRegion = $datafactoryregion}
            return $resourceGroupInformation
        } else {
            Write-Host "Ok, let's start this part over"
            $resourceGroupInformation = DeployResourceGroup
            return $resourceGroupInformation
        }
    }
}

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
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"$PSScriptRoot/moderndatawarehouse/dpi30moderndatawarehouse.json`" -azureSqlServerName `"$dbservername`" -azureSqlServerAdminLogin `"$dbadminlogin`" -azureSqlDataWarehouseName `"$dwname`" -databricksWorkspaceName `"$databricksname`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname`" -dataFactoryRegion `"$DataFactoryRegion`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot/moderndatawarehouse/dpi30moderndatawarehouse.json" -azureSqlServerName $dbservername -azureSqlServerAdminLogin $dbadminlogin -azureSqlServerAdminPassword $dbadminpassword -azureSqlDataWarehouseName $dwname -databricksWorkspaceName $databricksname -storageAccountName $storagename -dataFactoryName $dfname -dataFactoryRegion $DataFactoryRegion
    }
}

function DeploySimpleTemplate {
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

function DeployTemplate {
    # Moved initial deployment tree to secondary function to allow for easier expansion if we have more templates in the future
    Param(
        # The Template name we intend to deploy
        $template
    )
    $resourceGroupInformation = DeployResourceGroup
    if ($template -eq "datawarehouse") {
        DeployDWTemplate -ResourceGroupName $resourceGroupInformation.ResourceGroupName -DataFactoryRegion $resourceGroupInformation.DataFactoryRegion
    }
    if ($template -eq "simple") {
        DeploySimpleTemplate -ResourceGroupName $resourceGroupInformation.ResourceGroupName -DataFactoryRegion $resourceGroupInformation.DataFactoryRegion
    }
}

$datawarehousedescription = @"
`r`nBased on your answers we suggest the Modern Data Warehouse template.
It will deploy the following to your selected Azure Subscription:
    * Azure Data Factory
    * Azure Data Lake Gen 2
    * Azure Databricks
    * Azure Synapse Analytics (formerly Azure Data Warehouse)
"@

$simpledescription = @"
`r`nBased on your answers we suggest the Simple template.
It will deploy the following to your selected Azure Subscription:
    * SQL Azure Hyperscale Database (Gen 5 2 Cores, 1 readable secondary)
    * Azure Storage Account (Blob Storage)
    * Azure Data Factory
"@

# Our code entry point, We verify the subscription and move through the steps from here.
Clear-Host
$currentsub = Get-AzContext
$currentsubfull = $currentsub.Subscription.Name + " (" + $currentsub.Subscription.Id + ")"
Write-Host "Welcome to the DPi30 Deployment Wizard!"
Write-Host "Before we get started, we need to select the subscription for this deployment:`r`n"
#Write-Host  "Current Subscription: $($currentsubfull)`r`n" -ForegroundColor Yellow
$rawsubscriptionlist = Get-AzSubscription | where {$_.State -ne "Disabled"} | Select Name, Id 
$subscriptionlist = [ordered]@{}
$subscriptionlist.Add(0, "CURRENT SUBSCRIPTION: $($currentsubfull)")
$subcount = 1
foreach ($subscription in $rawsubscriptionlist) {
    $subname = $subscription.Name + " (" + $subscription.Id + ")"
    if($subname -ne $currentsubfull) {
        $subscriptionlist.Add($subcount, $subname)
        $subcount++
    }
}
$subscriptionlist.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key))" "$($_.Value)"}

$subselection = Read-Host "`r`nSubscription number"
if ($subselection -ne 0) {
    $selectedsub = $subscriptionlist.[int]$subselection
    $selectedsubid = $selectedsub.Substring($selectedsub.Length - 37).TrimEnd(")")
    $changesub = Select-AzSubscription -Subscription $selectedsubid
    Write-Host "`r`nChanged to Subscription $($changesub.Name)" -ForegroundColor Green
} 

if (DetermineTemplate) {
    Write-Host $datawarehousedescription
    $confirmation = Read-Host "`r`nWould you like to continue? (y/n)"
    if ($confirmation -eq "y") {
        DeployTemplate -template "datawarehouse"
    } else {
        exit
    }
} else {
    Write-Host $simpledescription
    $confirmation = Read-Host "`r`nWould you like to continue? (y/n)"
    if ($confirmation -eq "y") {
        DeployTemplate -template "simple"
    } else {
        exit
    }
 }
