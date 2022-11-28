# SecurityScoreAndBudgetAlert

The script will run to all the subscription for a given tenant.

Will check if the subscription is onboarded for the security score if not it will onboard
if yes will collect the security score

Will check for the presence of a budget alert with the specified name.
If not will create a budget alert with the parameters in **budget.json**


File **tenants.txt** contains the list of tennant and the script will loop all the subscriptions of those tenant

File **budget.json** contains the rules to apply to the budget section

The variable **$budgetName="provderBudget"** provide the name of the budget it will look for
