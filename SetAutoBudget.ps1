
#check if powershell version is 7.0 or higher and if not, warn the user and exit
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script requires PowerShell 7.0 or higher. Please update your PowerShell version and try again." -ForegroundColor Red
    exit
}

#check if Az module version 9 or higher is installed and if not, warn the user and install it or upgrade it
if ((Get-Module -Name Az -ListAvailable).Version.Major -lt 9) {
    Write-Host "The Az module is not installed. Installing it now..." -ForegroundColor Yellow
    Install-Module -Name Az -Scope CurrentUser -Force
}

$budgetName = "ContosoAuto"
$IncrementInPercentage = 10
$MinimumBudget = 100 #Minimum budget for subscription with low consumption
$Force = $true #Force delete the budget if it exists
$budgetNameManual = "ContosoManual" #this indicate that the budget is created manually and handled manually by the user


# Set the CSV file to be created in your script location
$MyPath = $PSScriptRoot
$MyCSVPath = $MyPath + "\budget.csv"
$MyAzPath = $MyPath + "\tenants.txt"
# Connect with the identity for which you would like to check Secure Score
# Only subscriptions with appropriate permissions will list a score.
Connect-AzAccount

#$MyAzTenants=Get-AzTenant
$MyAzTenants = Get-Content -Path $MyAzPath
$i = 0
$total = $MyAzTenants.Count
$progress = 0
$ProgressPreference = 'SilentlyContinue' 
foreach ($MyAzTenant in $MyAzTenants) {
    Write-Output "Checking tenant: $MyAzTenant" # Get all subscriptions within the selected tenant
    $MyAzSubscriptions = Get-AzSubscription -TenantId $MyAzTenant | Where-Object -Property State -NE 'Disabled'
    $i++
    $progress = [math]::Round(($i / $total) * 100)
    $ProgressPreference = 'Continue' 
    Write-Progress -Activity "Processing subscriptions" -Status "Processing subscription $i of $total" -PercentComplete $progress   
    $ProgressPreference = 'SilentlyContinue' 

    foreach ($MyAzSubscription in $MyAzSubscriptions) {
        #Write-Output "Checking subcription: $MyAzSubscription"
        Set-AzContext -Subscription $MyAzSubscription -Tenant $MyAzTenant # Get the Secure Score for each subscription$
        
        #show a progress bar in the cosole for this foreach loop
        
  
        #Login Rest Api
        
        $accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
        $apiUrl = "https://management.azure.com/subscriptions/" + $MyAzSubscription.Id + "/providers/Microsoft.Consumption/budgets?api-version=2021-10-01" 
        $budgetList = (Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -ContentType 'application/json' -Method GET).value 
        $checkBdg = ($budgetList | Where-Object -Property name -EQ $budgetNameManual).Count
        #check if the budget is handled manually and skip the subscription
        if ($checkBdg -eq 0) {

            $checkBdg = ($budgetList | Where-Object -Property name -EQ $budgetName).Count
            #control if checkBdg is greater than 0 and $force is true, delete the budget
            if ($checkBdg -gt 0 -and $Force -eq $true) {
                try {
                    
                    $apiUrl = "https://management.azure.com/subscriptions/" + $MyAzSubscription.Id + "/providers/Microsoft.Consumption/budgets/" + $budgetName + "?api-version=2021-10-01"
                    Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -ContentType 'application/json' -Method Delete 
                    #if return code is 200, the budget is deleted
                
                    $checkBdg = 0 
                    $MyCSVRow = @( [pscustomobject]@{
                        Date             = (Get-Date).Date;
                        TenantName       = $MyAzTenant.Name;
                        SubscriptionID   = $MyAzSubscription.Id;
                        SubscriptionName = $MyAzSubscription.Name;
                        LastMonthUsage   = 0;
                        budget           = 0;
                        Action           = "Budget deleted"
                    } )# Append the Secure Score to the CSV file$
                $MyCSVRow | Export-Csv $MyCSVPath -Append
                }
                catch {

                    $MyCSVRow = @( [pscustomobject]@{
                            Date             = (Get-Date).Date;
                            TenantName       = $MyAzTenant.Name;
                            SubscriptionID   = $MyAzSubscription.Id;
                            SubscriptionName = $MyAzSubscription.Name;
                            LastMonthUsage   = 0;
                            budget           = 0;
                            Action           = "Erroe deleting budget"
                        } )# Append the Secure Score to the CSV file$
                    $MyCSVRow | Export-Csv $MyCSVPath -Append
                    Write-Host "Error deleting budget $budgetName in subscription $MyAzSubscription" -ForegroundColor Red
                    
                }
            }
        
        
            if ($checkBdg -eq 0) {
                #Create a Budget
                $LastMonthUsage = [Math]::Ceiling(((Get-AzConsumptionUsageDetail -StartDate (Get-Date).AddMonths(-1) -EndDate (Get-Date)).PretaxCost |  measure-object -sum).sum)
                #increase last month usage by variable IncrementInPercentage
                $budget = [Math]::Ceiling($LastMonthUsage + ($LastMonthUsage * $IncrementInPercentage / 100))
                #control if budget is less than MinimumBudget and set it to MinimumBudget
                if ($budget -lt $MinimumBudget) {
                    $budget = $MinimumBudget
                }


                #startDate is the first day of the current month

                $startDate = (Get-Date -Day 1).ToString("yyyy-MM-ddT00:00:00Z")

                $body = Get-Content -Raw -Path $MyPath"\budget.json"
                
                #replace in body **AMOUNT** with last month usage

                $body = $body.Replace("**AMOUNT**", $LastMonthUsage)
                $body = $body.Replace("**STARTDATE**", $startDate)

                #check if Invoke-RestMethod returned 200


                try {
                    
            
                    
                    $apiUrl = "https://management.azure.com/subscriptions/" + $MyAzSubscription.Id + "/providers/Microsoft.Consumption/budgets/" + $budgetName + "?api-version=2021-10-01"
                    Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -ContentType 'application/json' -Method PUT  -Body $body
                    #check if returned status is 200
                
                   
                    $MyCSVRow = @( [pscustomobject]@{
                            Date             = (Get-Date).Date;
                            TenantName       = $MyAzTenant.Name;
                            SubscriptionID   = $MyAzSubscription.Id;
                            SubscriptionName = $MyAzSubscription.Name;
                            LastMonthUsage   = $LastMonthUsage;
                            budget           = $budget;
                            Action           = "Bunget created"
                        } )# Append the Secure Score to the CSV file$
                    $MyCSVRow | Export-Csv $MyCSVPath -Append
                }
                catch {
                    
                    Write-Output "Budget created for subscription: $MyAzSubscription"
                    $MyCSVRow = @( [pscustomobject]@{
                            Date             = (Get-Date).Date;
                            TenantName       = $MyAzTenant.Name;
                            SubscriptionID   = $MyAzSubscription.Id;
                            SubscriptionName = $MyAzSubscription.Name;
                            LastMonthUsage   = $LastMonthUsage;
                            budget           = $budget;
                            Action           = "Error creating budget"
                        } )# Append the Secure Score to the CSV file$
                    $MyCSVRow | Export-Csv $MyCSVPath -Append
                    Write-Host "Error creating budget for subscription: $MyAzSubscription" -ForegroundColor Red
                }
            
            
            
            
            }
        }

    }
}# You can extend the script with a foreach, cycling through all Secure Score controls for additional detail: Get-AzSecuritySecureScoreControl.
