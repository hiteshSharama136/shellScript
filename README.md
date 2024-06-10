Setting Branch Policies with Azure DevOps Script:

This PowerShell script automates the process of setting branch policies on Azure DevOps repositories. Follow these steps to configure and run the script.

Step1: Save the provided PowerShell script to your local machine with a .ps1 extension, e.g., Set-BranchPolicies.ps1

Step2: Open the script in a text editor and set the variables at the top of the script.

Step3: Execute the script in PowerShell



The script will fetch and display all projects within your Azure DevOps organization. Enter the number corresponding to the project you want to configure. 

Choose whether to apply branch policies to all repositories in the selected project or a specific repository:

Enter 1 to apply to all repositories.
Enter 2 to apply to a specific repository.

Review and Confirm: The script will display the selected repository/repositories and apply the following branch policies:
Minimum number of reviewers
Linked work items check
Comment resolution check
