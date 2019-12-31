<#
.Synopsis
DPi30 Decision and Deployment Tree

.Description
Script that will walk you through determining the proper DPi30 Template and help you deploy it step by step.
#>

function DetermineTemplate {
    # Questionaire to determine best fit, Current logic is if you answer yes at least twice you should use Modern Data Warehouse
    $dwscore = 0
    Clear-Host
    Write-Host "Let's determine the best deployment for your situation, Please answer the next few questions with y (yes) or n (no)."

    $confirmation = Read-Host "Will you have more than 1 TB of data? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Do you have a highly analytics-based workload? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Do you want to utilize any real-time or streaming data? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Would you like to integrate machine learning into your business intelligence? (y/n)"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Do you have Python, Scala, R, or Spark experience? (y/n)"
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
    
    Write-Host "First, let's create a Resource Group to put all these services in."
    $ResourceGroupName = Read-Host "What would you like the Resource Group named"
    $ExistingResourceGroup = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
    if($notPresent) {
        $regionfilter = ""
        $datafactoryregion = ""
        $geography = Read-Host "Which geography would you like deploy in? `n 1. US `n 2. Europe `n 3. Asia"
        switch ($geography)
        {
            "1" {
                $regionfilter = "US"
                $datafactoryregion = "East US"
                break
            }
            "US" {
                $regionfilter = "US"
                $datafactoryregion = "East US"
                break
            }
            "2" {
                $regionfilter = "Europe"
                $datafactoryregion = "North Europe"
                break
            }
            "Europe" {
                $regionfilter = "Europe"
                $datafactoryregion = "North Europe"
                break
            }
            "3" {
                $regionfilter = "Asia"
                $datafactoryregion = "Southeast Asia"
                break
            }
            "Asia" {
                $regionfilter = "Asia"
                $datafactoryregion = "Southeast Asia"
                break
            }
        }
        $locationlist = ((Get-AzLocation | Where-Object Providers -like "Microsoft.Databricks" | Where-Object Providers -like "Microsoft.Sql" | Where-Object DisplayName -like "* $regionfilter*").DisplayName)
        Write-Host "Here are the regions availble for deployment: "
        Write-Host $locationlist -Separator ", "
        Write-Host "Which region would you like the Resource Group in"
        $rglocation = Read-Host
        # Assign to prevent object being returned in function
        $resourcegroupreturnhold = New-AzResourceGroup -Name $ResourceGroupName -Location $rglocation -Tag @{dpi30="True"}
        Write-Host "Your new Resource Group $ResourceGroupName has been deployed."
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
    Clear-Host
    Write-Host "Now let's get the Modern Data Warehouse template deployed, just a few questions and we can get this kicked off."
    $dbservername = Read-Host "What would you like to name the Database Server?"
    $dbadminlogin = Read-Host "What username would you like to use for the Database Server?"
    $dbadminpassword = Read-Host "Password" -AsSecureString
    $dwname = Read-Host "What would you like to name the Data Warehouse?"
    $databricksname = Read-Host "What would you like to name the Databricks Workspace?"
    $storagename = Read-Host "What would you like to name the Data Lake storage account?"
    $dfname = Read-Host "What would you like to name the Data Factory?"
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
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"$PSScriptRoot\dpi30\moderndatawarehouse\dpi30moderndatawarehouse.json`" -azureSqlServerName `"$dbservername`" -azureSqlServerAdminLogin `"$dbadminlogin`" -azureSqlDataWarehouseName `"$dwname`" -databricksWorkspaceName `"$databricksname`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname`" -dataFactoryRegion `"$DataFactoryRegion`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot\dpi30\moderndatawarehouse\dpi30moderndatawarehouse.json" -azureSqlServerName $dbservername -azureSqlServerAdminLogin $dbadminlogin -azureSqlServerAdminPassword $dbadminpassword -azureSqlDataWarehouseName $dwname -databricksWorkspaceName $databricksname -storageAccountName $storagename -dataFactoryName $dfname -dataFactoryRegion $DataFactoryRegion
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
    Clear-Host
    Write-Host "Now let's get the Simple template deployed, just a few questions and we can get this kicked off."
    $dbservername = Read-Host "What would you like to name the Database Server?"
    $dbadminlogin = Read-Host "What username would you like to use for the Database Server?"
    $dbadminpassword = Read-Host "Password" -AsSecureString
    $dbname = Read-Host "What would you like to name the Database?"
    $storagename = Read-Host "What would you like to name the Blob storage account?"
    $dfname = Read-Host "What would you like to name the Data Factory?"
    Write-Host "Ok! That's everything, the deployment will take a few minutes, to confirm:"
    $confirmtext = @"

    Resource Group Name:             $ResourceGroupName
    Database Server Name:            $dbservername
    Database Server Login:           $dbadminlogin
    Database Name:                   $dwname
    Blob Storage Account Name:       $storagename
    Data Factory Name:               $dfname

    To re-run in case of failure you can use:
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"$PSScriptRoot\dpi30\simple\dpi30simple.json`" -azureSqlServerName `"$dbservername`" -azureSqlServerAdminLogin `"$dbadminlogin`" -azureSqlDatabaseName `"$dbname`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname` -dataFactoryRegion `"$DataFactoryRegion`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot\dpi30\simple\dpi30simple.json" -azureSqlServerName $dbservername -azureSqlServerAdminLogin $dbadminlogin -azureSqlServerAdminPassword $dbadminpassword -azureSqlDataWarehouseName $dbname -storageAccountName $storagename -dataFactoryName $dfname -dataFactoryRegion $DataFactoryRegion
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
Based on your answers we suggest the Modern Data Warehouse template.
It will deploy the following to your selected Azure Subscription:
    * Azure Data Factory
    * Azure Data Lake Gen 2
    * Azure Databricks
    * Azure Synapse Analytics (formerly Azure Data Warehouse)
"@

$simpledescription = @"
Based on your answers we suggest the Simple template.
It will deploy the following to your selected Azure Subscription:
    * SQL Azure Hyperscale Database (Gen 5 2 Cores, 1 readable secondary)
    * Azure Storage Account (Blob Storage)
    * Azure Data Factory
"@

# Our code entry point, We verify the subscription and move through the steps from here.
Clear-Host
Write-Host "Welcome to the DPi30 Deployment Wizard!"
Write-Host "Before we get started, is this the correct Azure Subscription:" 
Write-Host (Get-AzContext).Subscription.Name -ForegroundColor Yellow
$confirmation = Read-Host "(y/n)"
if ($confirmation -eq "y") {
    if (DetermineTemplate) {
        Write-Host $datawarehousedescription
        $confirmation = Read-Host "Would you like to continue? (y/n)"
        if ($confirmation -eq "y") {
            DeployTemplate -template "datawarehouse"
        } else {
            exit
        }
    } else {
        Write-Host $simpledescription
        $confirmation = Read-Host "Would you like to continue? (y/n)"
        if ($confirmation -eq "y") {
            DeployTemplate -template "simple"
        } else {
            exit
        }
    }
} else {
    Write-Host "Please select the proper subscription with Select-AzSubscription and try again." -ForegroundColor Red
    exit
}