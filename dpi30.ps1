<#
.Synopsis
DPi30 Decision and Deployment Tree

.Description
Script that will walk you through determining the proper DPi30 Template and help you deploy it step by step.
#>

#Included files to make our script significantly more readable.
try {
    . ("$PSScriptRoot/includes/validation.ps1")
    . ("$PSScriptRoot/includes/determinetemplate.ps1")
    . ("$PSScriptRoot/includes/deployresourcegroup.ps1")
    . ("$PSScriptRoot/includes/deploymoderndatawarehouse.ps1")
    . ("$PSScriptRoot/includes/deploysimple.ps1")
    . ("$PSScriptRoot/includes/deploymanagedinstance.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}

function DeployTemplate {
    # Moved initial deployment tree to secondary function to allow for easier expansion if we have more templates in the future
    Param(
        # The Template name we intend to deploy
        $template
    )
    Clear-Host
    # Create our resource group to deploy our azure resources to
    $resourceGroupInformation = DeployResourceGroup
    if ($template -eq "moderndatawarehouse") {
        DeployDWTemplate -ResourceGroupName $resourceGroupInformation.ResourceGroupName -DataFactoryRegion $resourceGroupInformation.DataFactoryRegion
    }
    if ($template -eq "simple") {
        DeploySimpleTemplate -ResourceGroupName $resourceGroupInformation.ResourceGroupName -DataFactoryRegion $resourceGroupInformation.DataFactoryRegion
    }
    if ($template -eq "managedinstance") {
        DeployManagedInstanceTemplate -ResourceGroupName $resourceGroupInformation.ResourceGroupName -DataFactoryRegion $resourceGroupInformation.DataFactoryRegion
    }
}

# Our code entry point, We verify the subscription and move through the steps from here.
Clear-Host
$currentsub = Get-AzContext
$currentsubfull = $currentsub.Subscription.Name + " (" + $currentsub.Subscription.Id + ")"
Write-Host "Welcome to the DPi30 Deployment Wizard!"
Write-Host "Before we get started, we need to select the subscription for this deployment:`r`n"
#Write-Host  "Current Subscription: $($currentsubfull)`r`n" -ForegroundColor Yellow
$rawsubscriptionlist = Get-AzSubscription | Where-Object {$_.State -ne "Disabled"} | Sort-Object -property Name | Select-Object Name, Id 
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

#Validating numeric input for subscription
do{
  $subselection = Read-Host "`r`nSubscription number"
  $intref = 0
  if(  ![int32]::TryParse( $subselection , [ref]$intref ))
  {
    Write-Host "Enter a valid number for one of the above Subscriptions" -ForegroundColor Red
  }
} until ($intref -gt 0 -or $subselection -eq '0')

if ($subselection -ne 0) {
    $selectedsub = $subscriptionlist.[int]$subselection
    $selectedsubid = $selectedsub.Substring($selectedsub.Length - 37).TrimEnd(")")
    $changesub = Select-AzSubscription -Subscription $selectedsubid
    Write-Host "`r`nChanged to Subscription $($changesub.Name)" -ForegroundColor Green
} 

Clear-Host
$template = DetermineTemplate
switch ($template) {
    "moderndatawarehouse" {
        Write-Host $datawarehousedescription
        $confirmation = Read-Host "`r`nWould you like to continue? (y/n)"
        if ($confirmation -eq "y") {
            DeployTemplate -template $template
        } else {
            exit
        }
        break
    }
    "simple" {
        Write-Host $simpledescription
        $confirmation = Read-Host "`r`nWould you like to continue? (y/n)"
        if ($confirmation -eq "y") {
            DeployTemplate -template $template
        } else {
            exit
        }
        break
    }
    "managedinstance" {
        Write-Host $managedinstancedescription
        $confirmation = Read-Host "`r`nWould you like to continue? (y/n)"
        if ($confirmation -eq "y") {
            DeployTemplate -template $template
        } else {
            exit
        }
        break
    }
}
