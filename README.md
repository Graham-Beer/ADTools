# ADTools
PowerShell code to help with Active Directory Administration

### *Move-ADUserToTargetOU.ps1* 
Function to move Users who already exist within Active Directory to a target OU group. 
Takes a file with a list of UserPrincipalName.  
**Usage** ```Move-AdUserToTargetOU -PathToCsv C:\temp\Users.csv -OUGroup 'NewUsers' -Verbose```
