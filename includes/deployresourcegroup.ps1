<#
.Synopsis
DPi30 Deploy Resource Group

.Description
Initial Resource Group deployment that determines geography and region and finally creates the resource group where all Azure resources will be deployed.
#>
function DeployResourceGroup {
    # Function to gather information and deploy the resource group
    
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
        
        #Validating numeric input for rg geography  
        do{
            $geographyselection = Read-Host "`r`nGeography Number"
            $intref = 0
            if(  ![int32]::TryParse( $geographyselection , [ref]$intref ))
            {
                Write-Host "Enter a valid number for one of the above Geographies" -ForegroundColor Red
            }
        } until ($intref -gt 0 -or $geographyselection -eq '0')
        
        $datafactoryregion = $datafactoryregions[$geographylist.[int]$geographyselection]
        #Write-Host "Selected $($geographyselection) which is $($geographylist.[int]$geographyselection) and our Data Factory region is $($datafactoryregion)"
        
        #Prompting for region selection.
        $rawlocationlist = ((Get-AzLocation | Where-Object Providers -like "Microsoft.Databricks" | Where-Object Providers -like "Microsoft.Sql" | Where-Object DisplayName -like "* $($geographylist.[int]$geographyselection)*")) | Sort-Object -property DisplayName | Select-Object DisplayName
        Write-Host "`r`nHere are the regions available for deployment:`r`n"
        $locationlist = [ordered] @{}

        for($i=0;$i -lt $rawlocationlist.Length;$i++)
        {
            $locationlist.Add($i + 1, $rawlocationlist[$i].DisplayName)
        }
        $locationlist.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key))" "$($_.Value)"}

        #Validating numeric input for rg region  
        do{
            $rglocation = Read-Host "`r`nRegion Number"
            $intref = 0
            if(  ![int32]::TryParse( $rglocation , [ref]$intref ))
            {
                Write-Host "`Enter a valid number for one of the above Regions" -ForegroundColor Red
            }
        } until ($intref -gt 0 -or $rglocation -eq '0')
        
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
            Write-Host "`r`nOk, let's start this part over" -ForegroundColor Yellow
            $resourceGroupInformation = DeployResourceGroup
            return $resourceGroupInformation
        }
    }
}