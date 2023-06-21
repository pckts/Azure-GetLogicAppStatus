# List of necessary modules
$modules = @("Az.Accounts", "Az.LogicApp")

# Loop over all modules
foreach ($module in $modules) {
    # Check if the module is installed
    if (!(Get-Module -ListAvailable -Name $module)) {
        # If not installed, install the module
        Install-Module -Name $module -Force -AllowClobber
    }
    else {
        # If installed, import the module
        Import-Module $module
    }
}

# Connect to Azure with an interactive dialog for sign-in
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Prepare the array to hold the data
$logicAppStatus = @()

# Loop over all subscriptions
foreach ($subscription in $subscriptions) {
    # Set the active subscription for subsequent commands
    Set-AzContext -SubscriptionId $subscription.Id

    # Get all resource groups in the subscription
    $resourceGroups = Get-AzResourceGroup

    # Loop over all resource groups
    foreach ($resourceGroup in $resourceGroups) {
        # Get all Logic Apps in the resource group
        $logicApps = Get-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName

        # Loop over all Logic Apps
        foreach ($logicApp in $logicApps) {
            # Prepare an object to hold this logic app's data
            $logicAppData = New-Object PSObject

            # Set the name, subscription, and resource group
            $logicAppData | Add-Member -NotePropertyName Name -NotePropertyValue $logicApp.Name
            $logicAppData | Add-Member -NotePropertyName Subscription -NotePropertyValue $subscription.Name
            $logicAppData | Add-Member -NotePropertyName ResourceGroup -NotePropertyValue $resourceGroup.ResourceGroupName

            # Check if Logic App is enabled
            if ($logicApp.State -eq "Enabled") {
                
                # Get the last run of the Logic App
                $lastRun = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroup.ResourceGroupName -Name $logicApp.Name | Sort-Object StartTime -Descending | Select-Object -First 1

                # If the last run exists, add its status to the object
                if ($null -ne $lastRun) {
                    $logicAppData | Add-Member -NotePropertyName Status -NotePropertyValue $lastRun.Status
                }
                # If the last run does not exist, add 'Never Run' to the object
                else {
                    $logicAppData | Add-Member -NotePropertyName Status -NotePropertyValue "Never Run"
                }
            }
            # If the Logic App is not enabled, add 'Disabled' to the object
            else {
                $logicAppData | Add-Member -NotePropertyName Status -NotePropertyValue "Disabled"
            }

            # Add this logic app's data to the array
            $logicAppStatus += $logicAppData
        }
    }
}

# Export the data to a CSV file
$logicAppStatus | Export-Csv -Path .\LogicAppStatus.csv -NoTypeInformation -Encoding UTF8
