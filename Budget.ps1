
#check if powershell version is 7.0 or higher and if not, warn the user and exit
if($PSVersionTable.PSVersion.Major -lt 7)
{
    Write-Host "This script requires PowerShell 7.0 or higher. Please update your PowerShell version and try again." -ForegroundColor Red
    exit
}

#check if Az module version 9 or higher is installed and if not, warn the user and install it or upgrade it
<#
if((Get-Module -Name Az -ListAvailable).Version.Major -lt 9)
{
    Write-Host "The Az module is not installed. Installing it now..." -ForegroundColor Yellow
    Install-Module -Name Az -Scope CurrentUser -Force -SkipPublisherCheck
}
#>
$budgetName="myBudget"


# The tenant csv must be in the format XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX,100
# first value is the tenant, second value is the budget for the tenant
$MyPath=$PSScriptRoot
$MyAzPath=$MyPath+"\tenants.csv"

# Connect with the identity for which you would like to check Secure Score
# Only subscriptions with appropriate permissions will list a score.
Connect-AzAccount

#$MyAzTenants=Get-AzTenant
$MyAzTenantsAndBudgets=Get-Content -Path $MyAzPath

foreach($MyAzTenantBudget in $MyAzTenantsAndBudgets){
    $MyAzTenantAndBudgetSplitted = $MyAzTenantBudget.split(",")
    $MyAzTenant = $MyAzTenantAndBudgetSplitted[0]
    $Budegt4Tenant = $MyAzTenantAndBudgetSplitted[1]
    Write-Output "Checking tenant: $MyAzTenant" # Get all subscriptions within the selected tenant
    $MyAzSubscriptions = Get-AzSubscription -TenantId $MyAzTenant | Where-Object -Property State -NE 'Disabled'

    foreach($MyAzSubscription in $MyAzSubscriptions){
       
        #Login Rest Api
        $accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
        $apiUrl="https://management.azure.com/subscriptions/"+$MyAzSubscription.Id+"/providers/Microsoft.Consumption/budgets?api-version=2021-10-01" 
        $checkBdg= ((Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $apiUrl -ContentType 'application/json' -Method GET -Verbose).value| Where-Object -Property name -EQ $budgetName).Count
        if ($checkBdg -eq 0){
            #Create Budget
            $body= Get-Content -Raw -Path $MyPath"\budget2.json"
            $body = $body.Replace("{{budgetValue}}", $Budegt4Tenant)
           
            $apiUrl="https://management.azure.com/subscriptions/"+$MyAzSubscription.Id+"/providers/Microsoft.Consumption/budgets/"+ $budgetName  +"?api-version=2021-10-01"
            Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $apiUrl -ContentType 'application/json' -Method PUT -Verbose -Body $body

        }

    }
}# You can extend the script with a foreach, cycling through all Secure Score controls for additional detail: Get-AzSecuritySecureScoreControl.



