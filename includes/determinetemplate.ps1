<#
.Synopsis
DPi30 Determine Template Function

.Description
Determines the best template to deploy based on the questions asked.
#>
function DetermineTemplate {
    # Questionaire to determine best fit, Current logic is if you answer yes at least twice you should use Modern Data Warehouse, otherwise we check if you want to use any DBMI features
    $dwscore = 0
    Write-Host "`r`nLet's determine the best deployment for your situation, Please answer the next few questions with y (yes) or n (no)."

    
    $dwscore = DwCalculator "`r`nWill you have more than 1 TB of data? (y/n)" $dwscore
    
    $dwscore = DwCalculator "`r`nDo you have a highly analytics-based workload? (y/n)" $dwscore
 
    $dwscore = DwCalculator "`r`nDo you want to utilize any real-time or streaming data? (y/n)" $dwscore

    $dwscore = DwCalculator "`r`nWould you like to integrate machine learning into your business intelligence? (y/n)" $dwscore

    $dwscore = DwCalculator "`r`nDo you have Python, Scala, R, or Spark experience? (y/n)" $dwscore

    if ($dwscore -ge 2) {
        return "moderndatawarehouse"
    } else {

        while(1) {
            $confirmation = Read-Host "`r`nWould you like to use SQL Agent, Cross Database Queries, or replicate to other SQL Servers? (y/n)"
            $check = validateResponse $confirmation "bool"
            if ($check) {
                if ($confirmation -eq "y") {
                    return "managedinstance"
                } else {
                    return "simple"
                }
            }
        }
    }
}

function DwCalculator {
    Param(
        #question asked
        $question,
        #Score for DW
        $dwscore
    )
    
    while(1) {
        $confirmation = Read-Host $question
        $check = validateResponse $confirmation "bool"
        if ($check) {
            if ($confirmation.ToLower().SubString(0,1) -eq "y") {
                $dwscore++
            }
            break
        }
    }
    return $dwscore
}