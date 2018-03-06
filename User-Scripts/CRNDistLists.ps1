########################################################################
####                                                                ####
####    Script to create CRN distribution lists                     ####
####                                                                ####
####    It should run daily at 3:00AM during drop/add               ####
####    on Utility002     					    					####
####                                                                ####
####    6.30.2017 --- Tierney Jackson!                              ####
####                                                                ####
########################################################################

#### Load the AD module and the SQL snapins
Import-Module ActiveDirectory
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

#### Get the date and convert it to a usuable format.  Two variables because I need different styles.
$date = date -format G
$date2 = date -format s
$date2 = $date2.replace("-","")
$date2 = $date2.replace(":","")
$date2 = $date2.replace("T","_")

#### Capture Output to a file so we can ignore it and delete it when it fills the disk
$oPath = "c:\scripts\logs\CRNDistLists\CRNDistList_" + $date2 + ".txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $oPath -append

#### Get the current termcode.  'Termcode' is a Sue-ism and some people don't know what it means.  It is actually a very accurate
#### portmonteau of the words 'term' and 'code.'  It is a 6-digit code that represents the current term, such as '201720.'
#### It's much easier to say than 'reporting_academic_period' and a hell of a lot easier to type in scripts.

###This never worked in time for classes to start--hardcoding seems to be the only way to make it accurate
#$termcode = Invoke-SqlCmd -ServerInstance "DM-2012" -Database "Datamart" -Query "SELECT reporting_academic_period FROM dbo.[Current Term (Filter, General)]"
$termcode = "201820"
								
#### Variable for stored proc termcode parameters
#The following line will work if we ever get the termcode flip aligned with reality
#$ap = "@academic_period=" + $termcode.reporting_academic_period
$ap = "@academic_period=$termcode"
		
#### Get the list of groups from datamart into a variable
$groups = Invoke-SqlCmd -ServerInstance "DM-2012" -Database "Datamart" -Query "EXEC dbo.CRNDistListCourses $ap"

#### BEGIN BIG MAIN LOOOOP!!!!
foreach ($group in $groups) {
	
	#### Set the variable for stored proc CRN param
	$spCRN = "@CRN=" + $group.course_reference_number
	#### CHANGE THIS VARIABLE to $group.course_reference_number + "-TESTING" to test it. DON'T FORGET TO HIDE IT!!!!!!!!  See below, somewhere in that 'else' block
	$groupname = $group.course_reference_number
	
	
	#### Other information about the group
	$displayname = $group.displayname
	$description = $group.title_short_desc + " - (as of $date)"
	$email = $groupname + "@rhodes.edu"
	
	#### Check if the group already exists and if it does, update the description
	if (dsquery group -name $groupname){
	
				Set-ADgroup $groupname -Description $description -confirm:$false
									}
	else {
		#### If the group doesn't exist then create it ...  change the -Path parameter to "OU=DWTEST" for testing
			New-ADGroup -Name $groupname -SamAccountName $groupname -GroupCategory Distribution -GroupScope Global -DisplayName $displayname -Path "OU=CRN,OU=Groups,DC=rhodes,DC=edu" -Description $description	
		#### set the email address since you have to do this the first time you create a group:
		Set-ADGroup $groupname -Replace @{mail=$email} -confirm:$false
		#### Here's where you hide them, but you'll need to run this entire script from EXTOOLS instead (because Exchange!):
		#### Set-MailBox $groupname -HiddenFromAddressListsEnabled $true
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
		foreach ($student in $students) {[void]$SQLMembers.Add($student.id)}
	}
		
	
	if ($Instructors.primary_instructor_id.GetType().name -ne "DBNull") {$SQLMembers = $SQLMembers + $instructors.primary_instructor_id}
	
	if ($Instructors.instructor_id2.GetType().name -ne "DBNull") {$SQLMembers = $SQLMembers + $Instructors.instructor_id2}

	if ($Instructors.instructor_id3.GetType().name -ne "DBNull") {$SQLMembers = $SQLMembers + $Instructors.instructor_id3}
	

#### Convert SQLMembers to AD User names
$SQLMemberUnames = @()
$SQLMemberUnames = New-Object System.Collections.ArrayList($null)
foreach ($SQLMember in $SQLMembers) {
	$SQLMemberUName = Get-ADUser -filter {employeeNumber -eq $SQLMember} | select Name
	[void]$SQLMemberUNames.Add($SQLMemberUname)
	}
$SQLMemberUnames = [System.Collections.ArrayList]($SQLMemberUnames)
$SQLMemberUnames = $SQLMemberUnames | Sort Name
			
#### Get the current AD group members

$ADMembers = Get-ADGroupMember $groupname | select Name
$ADMembers = [System.Collections.ArrayList]($ADMembers)
$ADMembers = $ADMembers | Sort Name

#### iterate through the list of members and add the ones who need to be added:
#### OLD METHOD:   $SQLMembersToAdd = $SQLMemberUNames.name | Where {$ADMembers.name -notcontains $_}
$SQLMembersToAdd = @()
$SQLMembersToAdd = New-Object System.Collections.ArrayList($null)
ForEach ($MemberName in $SQLMemberUNames) {
	if ($ADMembers.name -notcontains $MemberName.Name) {
		$SQLMembersToAdd += $MemberName
		}
	}

if ($SQLMembersToAdd.count -ne 0) {
	foreach ($SQLMember in $SQLMembersToAdd) {
		Add-ADGroupMember $groupname -Members $SQLMember.name
		}
	}

Clear-Variable MemberName

#### compare the lists and remove the ones who have dropped
#### OLD METHOD:   $ADMembersToRemove = $ADMembers.Name | Where {$SQLMemberUNames.name -notcontains $_}
$ADMembersToRemove = @()
$ADMembersToRemove  = New-Object System.Collections.ArrayList($null)
ForEach ($MemberName in $ADMembers) {
	if ($SQLMemberUNames.Name -notcontains $MemberName.name) {
		$ADMembersToRemove += $MemberName
		}
	}

if ($ADMembersToRemove.count -ne 0) {
	foreach ($ADMember in $ADMembersToRemove) {
		Remove-ADGroupMember $groupname -Members $ADMember.name -Confirm:$False
		}
	}


Clear-Variable MemberName
Remove-Variable instructors
	
#### END BIG MAIN LOOOOOP!!!!
}

#### process the exceptions list should stay outside the loop above and it will generate errors, but we can ignore them because we are professionals.
$exceptions = import-csv c:\scripts\CRNExceptions\CRNExceptions.txt
foreach ($exception in $exceptions) {
	Add-ADGroupMember $exception.crn -Members $exception.user
	}

$end = date -format G
#### Send a notice that the groups have been created
Send-MailMessage -SMTPServer "smtp.rhodes.edu" -To "walkerd@rhodes.edu" -Subject "CRN Distribution Lists" -From "NoReply@rhodes.edu" -Body "CRN Distribution Lists were updated.  Start:  $Date -- End:  $End"

Stop-Transcript