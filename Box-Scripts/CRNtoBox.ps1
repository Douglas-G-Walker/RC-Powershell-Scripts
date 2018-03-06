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

#### Capture Output to a file so we can ignore it and delete it when it fills the disk
$date2 = date -format s
$date2 = $date2.replace("-","")
$date2 = $date2.replace(":","")
$date2 = $date2.replace("T","_")
$oPath = "c:\scripts\logs\CRNToBox\CRNToBox_" + $date2 + ".txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $oPath -append

#### Import the BoxFunctions module
Import-Module BoxFunctions
$date = date -format G
#### This function checks the registry for the API token.  It can update the token if needed.
$token=Get-BoxToken


#####     THIS IS IMPORTANT:        #########################

####      Seriously ... read it ... #########################

#####Create the groups (we have to manually update this between semesters for now)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

$BoxGroups = Get-BoxAllGroups -token $token
$ADGroups = Get-ADGroup -Filter {Name -Like "28*"} -Properties Name,Displayname -SearchBase "OU=CRN,OU=Groups,DC=rhodes,DC=edu" | select Name,Displayname
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
	
$End = date -format G
#### Send a notice that the groups have been created
Send-MailMessage -SMTPServer "smtp.rhodes.edu" -To "walkerd@rhodes.edu" -Subject "Box CRN Groups" -From "NoReply@rhodes.edu" -Body "Box CRN groups have been updated.  Start:  $Date -- End:  $End"

Stop-Transcript
		
