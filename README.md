# Security Score and Budget Alert

This set of scripts help partners to mantain the healthines of their subscription.

## SecureScore.ps1

The script will run to all the subscription  for a given list of tenants.

File **tenants.txt** contains the list of tennant and the script will loop all the subscriptions of those tenant
______
1. Will check if the subscription is onboarded for the security score **if not it will onboard**
2. if yes will collect the security score
3. Otutput in MySecureScores.csv collected scores scores and Azure Defender Tasks
______
## ReadSecureScore.ps1

All of the above but does not enable Secure Score

## SetAutoBudget.ps1

The script will run to all the subscription for a given list of tenants.

____
1. Will check if a budget with the name **ContosoManual** exist. 
   - If yes will interprete that this subscription is handled manually go to the next one
2. Will check if a budget with the name **ContosoAuto** exist
   - If **"force"** parameter is specified will delete (and recreate in the steps below) it otherwise will skip to the next subscription leavinf the existing alert unchanged
3. Collect the consumption in the last month increase it by a percentage specified in IncrementInPercentage
4. Check if the consumption estimate is above MinimumBudget. Otherwise set consumption to the minimum
5. Create budget Alert with the parameters specified in the **budget.json**
6. Output budget.csv with the rules applied
_____

File **tenants.txt** contains the list of tenant and the script will loop all the subscriptions of those tenant

File **budget.json** contains the rules to apply to the budget section

The variable **$budgetName="ContosoAuto"** provide the name of the budget it will look for

The variable **$budgetNameManual = "ContosoManual"** provide the name of the subscription in manual mode
