Param(
  [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
  [string] [Parameter(Mandatory=$true)] $TemplateFile,
  [hashtable] [Parameter(Mandatory=$true)] $Parameters
)

Describe "DPi30 Simple Deployment Tests" {
  BeforeAll {
    $DebugPreference = "Continue"
  }

  AfterAll {
    $DebugPreference = "SilentlyContinue"
  }

  Context "When Simple deployed with parameters" {
    $output = Test-AzResourceGroupDeployment `
              -ResourceGroupName $ResourceGroupName `
              -TemplateFile $TemplateFile `
              -TemplateParameterObject $Parameters `
              -ErrorAction Stop `
               5>&1
               
    $outstring = [string]::Concat($output[27])
    $outjson = (($outstring -split "Body:")[1] | ConvertFrom-Json)
    $result = $outjson.properties

    It "Should be deployed successfully" {
      $result.provisioningState | Should -Be "Succeeded"
    }
  }
}