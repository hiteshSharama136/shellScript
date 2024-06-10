# Set variables
$organization = ""  # Replace with your Azure DevOps organization name
$pat = ""  # Replace with your Azure DevOps PAT
$branch = "refs/heads/uat"  # Branch to apply policies to

# Base64-encode the PAT
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# Function to call Azure DevOps REST API
function Invoke-AzDoApi {
    param (
        [string]$uri,
        [string]$method = "GET",
        [hashtable]$body = @{}
    )

    $headers = @{
        Authorization = ("Basic {0}" -f $base64AuthInfo)
    }

    if ($method -eq "GET") {
        $response = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
    } else {
        $response = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -Body ($body | ConvertTo-Json) -ContentType "application/json"
    }

    return $response
}

# Function to prompt for value if variable is empty
function Prompt-ForValue {
    param (
        [string]$variableName,
        [string]$promptMessage
    )
    
    if (-not (Get-Variable -Name $variableName -ValueOnly)) {
        Write-Host $promptMessage -NoNewline
        $value = Read-Host
        Set-Variable -Name $variableName -Value $value -Scope Global
    }
}

# Prompt for organization name and PAT if not set
Prompt-ForValue -variableName "organization" -promptMessage "Enter your Azure DevOps organization name"
Prompt-ForValue -variableName "pat" -promptMessage "Enter your Azure DevOps PAT"

# Get all projects in the organization
$uri = "https://dev.azure.com/$organization/_apis/projects?api-version=6.0"
$projects = Invoke-AzDoApi -uri $uri

# Function to display numbered list and prompt for selection
function Prompt-ForSelection {
    param (
        [string[]]$items
    )

    Write-Host "Choose an option:"
    for ($i = 0; $i -lt $items.Length; $i++) {
        Write-Host "$($i + 1): $($items[$i])"
    }

    $selected = Read-Host -Prompt "Enter the number of your selection"
    return $selected
}

# Prepare project list with numbers 
$projectNames = $projects.value.name
$projectSelection = Prompt-ForSelection -items $projectNames
$selectedProjectId = $projects.value[$projectSelection - 1].id
$project = $projects.value[$projectSelection - 1].name

Write-Host "You selected project: $project"

# Get all repositories in the selected project
$uri = "https://dev.azure.com/$organization/$project/_apis/git/repositories?api-version=6.0"
$repositories = Invoke-AzDoApi -uri $uri

# Prepare repository list with numbers
$repositoryNames = $repositories.value.name
$repositorySelection = Prompt-ForSelection -items $repositoryNames

# Prompt for applying policies to all repositories or a specific one
$option = Read-Host -Prompt "Enter 1 to apply branch policies to all repositories, or 2 to apply to a specific repository"

if ($option -eq "1") {
    foreach ($repo in $repositories.value) {
        $repositoryId = $repo.id
        Write-Host "Setting branch policies for $branch in repository $($repo.name)"
        # Set minimum number of reviewers
        az repos policy approver-count create --repository-id $repositoryId --branch $branch --minimum-approver-count 1 --creator-vote-counts False --allow-downvotes False --reset-on-source-push False --blocking True --enabled True --org "https://dev.azure.com/$organization" --project "$project" --detect true
        # Check for linked work items
        az repos policy work-item-linking create --repository-id $repositoryId --branch $branch --blocking True --enabled True --org "https://dev.azure.com/$organization" --project "$project" --detect true
        # Check for comment resolution
        az repos policy comment-required create --repository-id $repositoryId --branch $branch --blocking True --enabled True --org "https://dev.azure.com/$organization" --project "$project" --detect true
        Write-Host "Branch policies set for repository $($repo.name)."
    }
} elseif ($option -eq "2") {
    $selectedRepoId = $repositories.value[$repositorySelection - 1].id
    $selectedRepo = $repositories.value[$repositorySelection - 1].name
    Write-Host "You selected repository: $selectedRepo"
    Write-Host "Setting branch policies for $branch in repository $selectedRepo"
    # Set minimum number of reviewers
    az repos policy approver-count create --repository-id $selectedRepoId --branch $branch --minimum-approver-count 1 --creator-vote-counts False --allow-downvotes False --reset-on-source-push False --blocking True --enabled True --org "https://dev.azure.com/$organization" --project "$project" --detect true
    # Check for linked work items
    az repos policy work-item-linking create --repository-id $selectedRepoId --branch $branch --blocking True --enabled True --org "https://dev.azure.com/$organization" --project "$project" --detect true
    # Check for comment resolution
    az repos policy comment-required create --repository-id $selectedRepoId --branch $branch --blocking True --enabled True --org "https://dev.azure.com/$organization" --project "$project" --detect true
    Write-Host "Branch policies set for repository $selectedRepo."
} else {
    Write-Host "Invalid option. Please enter either 1 or 2."
}

Write-Host "Branch policies script execution completed."