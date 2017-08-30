Function Move-ADUserToTargetOU {

    [cmdletbinding()]
    param (
        [string]$path,
        [string]$OUGroup
    )

    Begin {
        Write-Verbose -Message "[BEGIN  ] Function to move Users to '$OUGroup' OU"
        # Get user list
        $UPNlist = Import-Csv -Path $Path -Encoding UTF8
    }

    Process {
    # Obtain Forest
    $forest = (Get-ADForest).name

        foreach ($upn in $UPNlist.UserPrincipalName) {
    
            # Get User Parameters
            $params = @{
                Filter            = { UserPrincipalName -eq $upn }
                Properties        = 'DistinguishedName'
                Server            = "${forest}:3268"
                ErrorAction       = 'Stop'
            }
        
            # Find User
            Try {
                Write-Verbose -Message "[PROCESS] Getting User details from Active Directory"
                $ADAccount = Get-ADUser @params
            } catch {
                Write-Error -Message $_.Exception.Message -ErrorAction Stop
            }

            If ($ADAccount) {

                # Get Primary DC user is in with string manipulation on DistinguishedName
                $DCSplit = $ADAccount.DistinguishedName.split(',') | 
                    Where-Object { $_ -like "dc=*"} | 
                    Foreach-Object { $_ -replace "dc=",'' }
                
                # Define Server Name
                $Server = $DCSplit -join '.'

                # Remove whitespace
                $Server = ([string]$Server).trim()

                ## OU Details
                # Create Filter
                $OUFilter = { Name -like "*$OUGroup*" }
                
                # TargetOU
                Write-Verbose -Message "[PROCESS] Getting Target OU"
                $TargetOU = Get-ADOrganizationalUnit -Filter $OUFilter -Server $Server

                # Get users current OU
                $UserOU = ($ADAccount.DistinguishedName -split ",",2)[1]
 
                If (-not ($UserOU -eq $TargetOU.DistinguishedName)) {

                    # Move User Parameters
                    $Move = @{
                        Identity    = $ADAccount
                        TargetPath  = $TargetOU
                        Server      = $Server
                        ErrorAction = 'Stop'
                    }
        
                    # Perform Move
                    Try {
                        Write-Verbose -Message "[PROCESS] Moving user: $($ADAccount.UserPrincipalName)"
                        Move-ADObject @Move
                
                        Write-Verbose -Message "[PROCESS] Target Server: $Server"
                        Write-Verbose -Message "[PROCESS] User moved to Target OU: $($Move.TargetPath)"
                    } catch {
                        Write-Error -Message $_.Exception.Message -ErrorAction Continue
                    }
                } else {
                    Write-Warning -Message "Already in correct OU: $($ADAccount.UserPrincipalName)"
                }
            } else {
                Write-Warning -Message "Not found in Active Directory: $upn" 
            }
        }
    }
    
    End {
        Write-Verbose -Message "[END    ] Completed OU moves"
    }
}

## Test Example
# Move-ADUserToMonitoredOU -path C:\Temp\Users.csv -Verbose