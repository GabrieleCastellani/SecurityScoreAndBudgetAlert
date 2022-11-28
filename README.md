# SecurityScoreAndBudgetAlert

The script will run to all the subscription for a given tenant.
______
1. Will check if the subscription is onboarded for the security score if not it will onboard
2. if yes will collect the security score

3. Will check for the presence of a budget alert with the specified name.
4. If not will create a budget alert with the parameters in **budget.json**
______

File **tenants.txt** contains the list of tennant and the script will loop all the subscriptions of those tenant

File **budget.json** contains the rules to apply to the budget section

The variable **$budgetName="provderBudget"** provide the name of the budget it will look for
