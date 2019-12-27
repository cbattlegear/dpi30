<#
.Synopsis
DPi30 Decision and Deployment Tree

.Description
Script that will walk you through determining the proper DPi30 Template and help you deploy it step by step.
#>

function DetermineTemplate {
    $dwscore = 0
    Write-Host "Let's determine the best deployment for your situation, Please answer the next few questions with y (yes) or n (no)."

    $confirmation = Read-Host "Will you have more that 1 TB of data? (y/n):"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Do you have a highly analytics based workload? (y/n):"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Do you want to utilize any real-time or streaming data? (y/n):"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Would you like to integrate machine learning into your business intelligence? (y/n):"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    $confirmation = Read-Host "Do you have Python, Scala, R, or Spark experience? (y/n):"
    if ($confirmation -eq "y") {
        $dwscore++
    }

    if ($dwscore -ge 2) {
        return $true
    } else {
        return $false
    }
}

function Deploy-ResourceGroup {
    Write-Host "First, let's create a Resource Group to put all these services in."
    $rgname = Read-Host "What would you like the Resource Group named?"
    Write-Host "Which region would you like the Resource Group in?"
    Write-Host "You can select from: "
    Write-Host ((Get-AzLocation | Where-Object Providers -like "Microsoft.Databricks" | Where-Object Providers -like "Microsoft.Sql" | Where-Object DisplayName -like "* US*").DisplayName) -Separator ", "
    $rglocation = Read-Host
    New-AzResourceGroup -Name $rgname -Location $rglocation -Tag @{dpi30="True"}
    Write-Host "Your new Resource Group $rgname has been deployed."
    return $rgname
}

function Deploy-DWTemplate {
    Param($ResourceGroupName)
    Write-Host "Now let's get the Modern Data Warehouse template deployed, just a few questions and we can get this kicked off."
    $dbservername = Read-Host "What would you like to name the Database Server?"
    $dbadminlogin = Read-Host "What username would you like to use for the Database Server?"
    $dbadminpassword = Read-Host "Password:" -AsSecureString
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
    New-AzResourceGroupDeployment -ResourceGroupName `"$ResourceGroupName`" -TemplateFile `"dpi30\moderndatawarehouse\dpi30moderndatawarehouse.json`" -azureSqlServerName `"$dbservername`" -azureSqlServerAdminLogin `"$dbadminlogin`" -azureSqlServerAdminPassword `"$dbadminpassword`" -azureSqlDataWarehouseName `"$dwname`" -databricksWorkspaceName `"$databricksname`" -storageAccountName `"$storagename`" -dataFactoryName `"$dfname`"
"@
    Write-Host $confirmtext
    $confirmation = Read-Host "Do you wish to continue? (y/n)"
    if ($confirmation -eq "y") {
        Write-Host "Deploying Template..."
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile dpi30\moderndatawarehouse\dpi30moderndatawarehouse.json -azureSqlServerName $dbservername -azureSqlServerAdminLogin $dbadminlogin -azureSqlServerAdminPassword $dbadminpassword -azureSqlDataWarehouseName $dwname -databricksWorkspaceName $databricksname -storageAccountName $storagename -dataFactoryName $dfname
    }
}

function Deploy-SimpleTemplate {
    Param($ResourceGroupName)
}

function Deploy-Template {
    Param($template)
    $rgname = Deploy-ResourceGroup
    if ($template -eq "datawarehouse") {
        Deploy-DWTemplate -ResourceGroupName $rgname
    }
    if ($template -eq "simple") {
        Deploy-SimpleTemplate
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
    * SQL Azure Database (Gen 5 2 Cores)
    * Azure Storage Account (Blob Storage)
    * Azure Data Factory
"@

Clear-Host
Write-Host "Welcome to the DPi30 Deployment Wizard!"
Write-Host "Before we get started, is this the correct Azure Subscription:" 
Write-Host (Get-AzContext).Subscription.Name -ForegroundColor Yellow
$confirmation = Read-Host "(y/n):"
if ($confirmation -eq "y") {
    if (DetermineTemplate) {
        Write-Host $datawarehousedescription
        $confirmation = Read-Host "Would you like to continue? (y/n):"
        if ($confirmation -eq "y") {
            $ResourceGroupName = Deploy-ResourceGroup
            Deploy-DWTemplate -ResourceGroupName $ResourceGroupName
        } else {
            exit
        }
    } else {
        Write-Host $simpledescription
        $confirmation = Read-Host "Would you like to continue? (y/n):"
        if ($confirmation -eq "y") {

        } else {
            exit
        }
    }
} else {
    Write-Host "Please select the proper subscription with Select-AzSubscription and try again." -ForegroundColor Red
    exit
}