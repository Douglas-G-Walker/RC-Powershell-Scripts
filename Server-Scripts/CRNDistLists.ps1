#### Get the date
$date = date -format G

#### Get the current termcode
$termcode = Invoke-SqlCmd -ServerInstance "DM-2012" -Database "Datamart" -Query "SELECT reporting_academic_period FROM dbo.[Current Term (Filter, General)]"
								
#### Variable for stored proc termcode parameters
$ap = "@academic_period=" + $termcode.reporting_academic_period
		
#### Get the list of groups from datamart into a variable
$groups = Invoke-SqlCmd -ServerInstance "DM-2012" -Database "Datamart" -Query "EXEC dbo.CRNDistListCourses $ap"


foreach ($group in $groups) {
	
	#### Set the variable for stored proc CRN param
	$spCRN = "@CRN=" + $group.course_reference_number
	#### CHANGE THIS VARIABLE to $group.course_reference_number + "-TESTING" to test it.
	$groupname = $group.course_reference_number
	
	
	#### Other information about the group
	$displayname = $group.displayname
	$description = $group.title_short_desc + " - (as of $date)"
	$email = $groupname + "@rhodes.edu"
	
	#### Check if the group already exists and if it does, update the description
	if (dsquery group -name $groupname){
	
				Set-ADgroup $groupname -Description $description
									}
	else {
		#### If the group doesn't exist then create it ...  change the -Path parameter to "OU=DWTEST" for testing
			New-ADGroup -Name $groupname -SamAccountName $groupname -GroupCategory Distribution -GroupScope Global -DisplayName $displayname -Path "OU=CRN,OU=Groups,DC=rhodes,DC=edu" -Description $description	
		#### set the email address since you have to do this the first time you create a group:
		Set-ADGroup $groupname -Replace @{mail=$email}			
			}
	
	#### Get the list of students from datamart into a variable
	$Students = Invoke-SqlCmd -ServerInstance "DM-2012" -Database "Datamart" -Query "EXEC dbo.ActiveStudentCRNs $ap,$spCRN"
						
	#### Get the list of instructors from datamart into a variable
	$instructors = Invoke-SqlCmd -ServerInstance "DM-2012" -Database "Datamart" -Query "EXEC dbo.CRNDistListInstructors  $ap,$spCRN"
							
	#### Combine the lists by creating an arraylist
	$SQLMembers = @()
	$SQLMembers = New-Object System.Collections.ArrayList($null)
	
	#### Add Students to the arraylist
	if ($students) {
		foreach ($student in $students) {$SQLMembers.Add($student.id)}
	}
		
	$INST1 = $Instructors.primary_instructor_id
	if ($INST1.GetType().name -eq "DBNull") {}
	else {
		$SQLMembers = $SQLMembers + $instructors.primary_instructor_id
	}
	
	$INST2 = $Instructors.instructor_id2
	if ($INST2.GetType().name -eq "DBNull") {}
	else {		
		$SQLMembers = $SQLMembers + $Instructors.instructor_id2
		}
	
	$INST3 = $Instructors.instructor_id3
	if ($INST3.GetType().name -eq "DBNull") {}
	else {
		$SQLMembers = $SQLMembers + $Instructors.instructor_id3
		}

#### Convert SQLMembers to AD User names
$SQLMemberUnames = @()
$SQLMemberUnames = New-Object System.Collections.ArrayList($null)
foreach ($SQLMember in $SQLMembers) {
	$SQLMemberUName = Get-ADUser -filter {employeeNumber -eq $SQLMember} | select Name
	$SQLMemberUNames.Add($SQLMemberUname)
	}
			
#### Get the current AD group members
$ADMembers = Get-ADGroupMember $groupname | select Name

#### iterate through the list of members and add the ones who need to be added:
$SQLMembersToAdd = $SQLMemberUNames.name | Where {$ADMembers.name -notcontains $_}

foreach ($SQLMember in $SQLMembersToAdd) {
	Add-ADGroupMember $groupname -Members $SQLMember
	}

#### compare the lists and remove the ones who have dropped
$ADMembersToRemove = $ADMembers.Name | Where {$SQLMemberUNames.name -notcontains $_}

foreach ($ADMember in $ADMembersToRemove) {
	Remove-ADGroupMember $groupname -Members $ADMember.name
	}
}

#### Send a notice that the groups have been created
Send-MailMessage -SMTPServer "smtp.rhodes.edu" -To "walkerd@rhodes.edu" -Subject "CRN Distribution Lists" -From "NoReply@rhodes.edu" -Body "CRN Distribution Lists were updated on $Date"