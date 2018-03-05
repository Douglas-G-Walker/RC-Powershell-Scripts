########################################################################
####                                                                ####
####    Script to use the CRN distribution lists as Box groups      ####
####                                                                ####
####    It uses the Box API (BoxFunctions)                          ####
####                                                                ####
####    It should run daily AFTER the CRNDistLists.ps1 script runs  ####
####    on Utility002                                               ####
####                                                                ####
####    10.5.2016 --- Doug Walker                                   ####
####                                                                ####
########################################################################

#### This function checks the registry for the API token.  It can update the token if needed and stores it in a variable.
$token=Get-BoxToken

#####Create the groups (in the Spring change the -Like from 1 to 2, in the summer from 2 to 3)
$BoxGroups = Get-BoxAllGroups -token $token
$ADGroups = Get-ADGroup -Filter {Name -Like "1710*"} `
			-Properties Name,Displayname -SearchBase "OU=CRN,OU=Groups,DC=rhodes,DC=edu" |
						select Name,Displayname		
$BoxGroupsNames = $BoxGroups.name
$ADGroupsNames = $ADGroups.name

#####Compare ADGroups with BoxGroups and create the groups that are missing
$ADGroupsNamesToCreate = $ADGroupsNames | Where  {
						$BoxGroupsNames -notcontains $_}
						
foreach ($ADGroupName in $ADGRoupsNamesToCreate) {
New-BoxGroup -token $token -name $ADGroupName
}

#####Add/Remove Box CRN-based group memberships
	foreach ($ADgroup in $ADgroupsNames) {
		#### Tricky part:  MATCH the ADgroup with the BoxGroup.name and get the BoxGroup.id
		$BoxGroup = $BoxGroups | where {$_.name -eq $ADGroup}
		  
		####Get the current Box group members (this goes into a hashtable as per the BoxFunctions module)
		$BoxMembers = Get-BoxGroupMembers -token $token -groupid $BoxGroup.id

		####Put the values from the hashtable into separate arraylists
		if ($BoxMembers) {
		$BoxMembersNames = New-Object System.Collections.ArrayList($BoxMembers.keys)
		$BoxMembersIDs = New-Object System.Collections.ArrayList($BoxMembers.values)
			}
			
		#####Get the current AD group members
		$ADMembers = Get-ADGroupMember -Identity $ADgroup
		$ADMemberNames = @()
		$ADMemberNames = New-Object System.Collections.ArrayList($null)
			####Append "@rhodes.edu" since M$ is too stupid to use their own login information
			foreach ($Member in $ADMembers) {$ADMemberNames += $Member.name + "@rhodes.edu"}
	
		#####Add new members
		####Compare the two lists
		$ADMembersToAdd = $ADMemberNames | Where {
											$BoxMembersNames -notcontains $_
											}
		
		
		if ($ADMembersToAdd) {
			foreach ($ADmember in $ADmembersToAdd) {
				$boxuserid = Get-BoxUserId $Admember -token $token 
				Add-BoxGroupMember -token $token -userid $boxuserid -groupid $boxgroup.id
			}
		}
		
		#####Remove students who've dropped	
		#####Compare the two lists in reverse
		$BoxMembersToRemove = $BoxMembersNames | Where {
														$ADMemberNames -notcontains $_
														}
		
		if ($BoxMembersToRemove) {
			foreach ($BoxMember in $BoxMemberToRemove) {
				$boxuserid = Get-BoxUserId $BoxMember -token $token
				Remove-BoxGroupMember -token $token -userid $boxuserid -groupid $boxgroup.id
				
			}
		}	
	}
		
