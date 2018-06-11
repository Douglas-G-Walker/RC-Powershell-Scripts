Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
#end Get-FileName
}

Function Create-StuDirs($User){
	#### Create Student Folders
	#### Doug Walker 08-29-2016

	$User
	#### Get first initial
	$Init = $User.SubString(0,1)

	#### Strip @rhodes.edu if it's there
	if ($User.Contains("@rhodes.edu")) {
			$User=$User.Replace("@rhodes.edu", "")
			}
			
	#### Check if it's a real user
	if (DSquery user -samid $user){
			$User=Get-ADUser $User
	}
	else {Write-host -foregroundcolor Red "No such user: " $user
		  Break}
			
	#### Get firstname and lastname from AD						}	
	$FN=$User.GivenName
	$LN=$User.Surname

	#### Set the path
	$Path = "\\fileserver\Student_Community\Student_Folders\" + $Init + "\" + $LN + "_" + $FN

	#### Create the directory
	if (!(Test-Path $path)){
		New-Item $path -type directory
	}

	else {write-host -foregroundcolor Red "The folder already exists!"
	write-host -foregroundcolor Red "If you KNOW this is a different person with the same name, a folder can be created with the class year appended (ex. lastname_firstname-17)."
	[console]::ForeGroundColor = "yellow"
	$ans = read-host "Please press Y to proceed, or any other key to exit."
	[console]::ForeGroundColor = "white"
#End Create-StuDirs
}

if ($ans -ne "Y") {
Break
} 
else {
	Try {
	$pathext = $User.name.SubString(5,3)
	$path = $path + $pathext
	new-item $path -type directory
	}
	Catch {Write-Host -foregroundcolor Red "Are you sure you're using a student username? I'm out of here.  Start over, man."}
	
}


#### Set permissions
	#### Get current ACLs
		$ACL=Get-Acl $path
	#### Turn off inheritence
		$ACL.SetAccessRuleProtection($true,$false)
		Set-Acl $path $ACL
	#### Get the updated ACLs and set the Domain Admins to full control
		$ACL=Get-Acl $path
		$UserACL=New-Object System.Security.AccessControl.FileSystemAccessRule("RHODES\Domain Admins","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
		$ACL.SetAccessRule($UserACL)
		Set-Acl $path $Acl
	#### Get the updated ACLs and set the Admins to full control
		$ACL=Get-Acl $path
		$UserACL=New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
		$ACL.SetAccessRule($UserACL)
		Set-Acl $path $Acl
	#### Get the updated ACLs and set the SYSTEM to full control
		$ACL=Get-Acl $path
		$UserACL=New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
		$ACL.SetAccessRule($UserACL)
		Set-Acl $path $Acl
	#### Get the updated ACLs and set the User to full control
		$ACL=Get-Acl $path
		$UserACL=New-Object System.Security.AccessControl.FileSystemAccessRule($user.name,"FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
		$ACL.SetAccessRule($UserACL)
		Set-Acl $path $Acl
	#### Get the updated ACLs and set the Faculty to write only
		$ACL=Get-Acl $path
		$FacACL=New-Object System.Security.AccessControl.FileSystemAccessRule("Rhodes\Faculty","ReadExtendedAttributes, ReadAttributes, Write, ReadPermissions, Synchronize","ContainerInherit,ObjectInherit", "None", "Allow")
		$ACL.SetAccessRule($FacACL)
		Set-Acl $path $Acl
}

Function Bulk-RemoveFromGroup {
	Write-host "This utility simply removes all the objects in the Grads OU from the Papercut, Box, Wireless, and MicroMain groups. You might see a lot of red errors while this runs, I don't do a lot of error checking.  Most likely, it just means that the user is not in the group.  The script will move on."
	[console]::ForeGroundColor = "yellow"
	$ans = read-host "Please press Y to proceed, or any other key to exit."
	[console]::ForeGroundColor = "white"
	if ($ans -ne "Y") {
		Break
		} 
	else {
		$users = Get-ADuser -SearchBase "OU=Grads,DC=rhodes,DC=edu" -filter *
		foreach ($user in $users) {Remove-ADGroupMember -identity PapercutUsers -member $user.name -Confirm:$false}
		foreach ($user in $users) {Remove-ADGroupMember -identity Box -member $user.name -Confirm:$false}
		foreach ($user in $users) {Remove-ADGroupMember -identity BoxFirstTimeUser -member $user.name -Confirm:$false}
		foreach ($user in $users) {Remove-ADGroupMember -identity Wireless_Students -member $user.name -Confirm:$false}
		foreach ($user in $users) {Remove-ADGroupMember -identity WebRequestUser -member $user.name -Confirm:$false}
		}
#End Bulk-RemoveFromGroup
}

Function Create-WritingCampUsers {
	
	########
	#				       	
	# 	Pay attention to variables		
	#            						
	#	You can alter the parameters 		
	#	(description,etc)			
	#  						
	#  	You can alter the groups array 		
	#						
	#   	As noted, the output CSV will 			
	#	be in the directory where you		
	#	saved the input CSV
	#  						
	#########
	write-host ""
	write-host "CSV should be in this format:  id,ln,fn,mn ---- Continue? y/n" -foregroundcolor red -backgroundcolor yellow
	$continue = read-host 
	write-host ""
	$continue = $continue.substring(0,1).tolower()
	if ($continue -ne "y")  {"Thanks for playing."; exit}

	$year = get-date -f yyyy
	$yr = get-date -f yy
	###start in the current directory
	$dir = $psscriptroot

	###read the csv of users in an array
	$csvIn = get-filename "c:\"
	$names = import-csv $csvIn

	###process each line in the array
	foreach ($name in $names) 
	{

		###generate a random 6 character password as a string
		$password = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})
			
		###check for existing username--up to 5 iterations of duplicate usernames
		if (($name.mn).length -ne 0) 
		{
			$unamechk = ($($name.ln).substring(0,3) + $($name.fn).substring(0,1) + $name.mn).tolower() + "-" + $yr
		} else {
			$unamechk = ($($name.ln).substring(0,3) + $($name.fn).substring(0,2)).tolower() + "-" + $yr
		}

		$exit = 0
		$count = 1

		do {
			Try{
				#see if the user already exists
				$user = get-aduser -identity $unamechk
					if ($count -eq 1) {
						$unamechk = $unamechk -replace "-$yr$", "$count-$yr"
					} else {
						$count2 = $count - 1
						$unamechk = $unamechk -replace "$count2-$yr$", "$count-$yr"
					}
					$count = $count + 1
					if ($count -gt 5) {$exit = 1}
					
				}
			Catch{
				$exit = 1
				}
			}
		While ($Exit -eq 0)

		###set the parameters for the new user
		$params = @{
			displayname = "$($name.ln)_$($name.fn)"
			givenname = $name.fn
			surname = $name.ln
			name = $unamechk
			samaccountname = $unamechk
			employeeid = $name.id
			employeeNumber = $name.id
			description = "Writing Camp Student $year"
			path = "OU=Temp Accounts,DC=rhodes,DC=edu"
			accountpassword = (convertto-securestring "$password" -asplaintext -force)
			enabled = $true
			changepasswordatlogon = $false
			userprincipalname = "$unamechk@rhodes.edu".tolower()
		}

		###create the user
		New-ADUser @Params

		###add user to groups
		$groups = "expressonelogin","papercutusers","students","wireless_students","WritingCamp"
		foreach ($group in $groups) 
			{
			add-adgroupmember -identity $group -members $params.samaccountname
			}
			
		write-host "Created account for: $params.displayname - $params.userprincipalname"
			
		###write this out to a csv for displayname,username, password
		###
		###--------->>>>>>   NOTE:  The CSV will be in the same directory as the input CSV.
		###
		$csvpath = get-childitem $csvIn
		$csvpath = $csvpath.directory.fullname
		$csv = new-object psobject
		$csv | add-member noteproperty id $params.employeeid
		$csv | add-member noteproperty lastname $params.surname
		$csv | add-member noteproperty firstname $params.givenname
		$csv | add-member noteproperty login $params.userprincipalname
		$csv | add-member noteproperty password $password
		$csv | export-csv -path $csvpath\writingcampaccounts_$year.csv -notypeinformation -append
		
		
	}
	
	write-host "Output saved at $csvpath\writingcampaccounts_$year.csv"
	
#End Create-WritingCampUsers
}

Function Create-StaffUsers {

	########
	#				       	
	# 	Pay attention to variables		
	#            						
	#	You can alter the parameters 		
	#	(description,etc)			
	#  						
	#  	You can alter the groups array 		
	#						
	#   	As noted, the output CSV will 			
	#	be in the directory where you		
	#	saved the input CSV
	#  						
	#########

	$continue = "n"
	write-host ""
	write-host "CSV should contain: lastname,firstname,rnumber,office -- Continue? y/n" -foregroundcolor red -backgroundcolor yellow
	$continue = read-host 
	write-host ""
	$continue = $continue.substring(0,1).tolower()

	if ($continue -ne "y")  {"Thanks for playing."; exit}
	
		###start in the current directory
		$dir = $psscriptroot
		$date = get-date -format MM-dd-yyyy

		
		$csvIn = get-filename "c:\"
		$names = import-csv $csvIn

		###process each line in the array
		foreach ($name in $names) 
		{

			###generate a random 6 character password as a string
			$password = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})
				
			###check for existing username--up to 5 iterations of duplicate usernames
			$unamechk = "$($name.last)$($name.first[0])".tolower()
			$exit = 0
			$count = 1
			
			do 
			{
				Try
				{
					#see if the user already exists
					$user = get-aduser -identity $unamechk
					$count = $count + 1
					$unamechk = $unamechk + $count
						if ($count -gt 5) {$exit = 1}
				}
				Catch
				{
					$exit = 1
				}
			}
			While ($Exit -eq 0)

			###set the parameters for the new user
			$params = @{
				displayname = "$($name.last)_$($name.first)"
				givenname = $name.first
				surname = $name.last
				name = $unamechk
				samaccountname = $unamechk
				office = $name.office
				employeeID = $name.rnumber
				employeeNumber = $name.rnumber
				description = "Staff"
				email = "$unamechk@rhodes.edu".tolower()
				path = "CN=Users,DC=rhodes,DC=edu"
				accountpassword = (convertto-securestring "$password" -asplaintext -force)
				enabled = $true
				changepasswordatlogon = $false
				userprincipalname = "$unamechk@rhodes.edu".tolower()
			}
		
			###create the user
			New-ADUser @Params

			###add user to groups
			$groups = "box","boxfirsttimeuser","expressonelogin","papercutusers","staff","staff_dl","facstaff","wireless_staff","webrequestuser"
			foreach ($group in $groups) 
			{
				add-adgroupmember -identity $group -members $params.samaccountname
			}
			
			write-host "Created account for: $params.displayname - $params.userprincipalname"
			
			###write this out to a csv for displayname,username, password
			###
			###--------->>>>>>   NOTE:  The CSV will be in the same directory as the input CSV.
			###
			$csvpath = get-childitem $csvIn
			$csvpath = $csvpath.directory.fullname
			$csv = new-object psobject
			$csv | add-member noteproperty id $params.employeeID
			$csv | add-member noteproperty name $params.displayname
			$csv | add-member noteproperty login $params.userprincipalname
			$csv | add-member noteproperty password $password
			$csv | export-csv -path $dir\StaffAccounts_CreatedOn_$date.csv -notypeinformation -append
		}
		
		write-host "Output saved at $csvpath\StaffAccounts_CreatedOn_$date.csv"
		
#End Create-StaffUsers
}

Function Create-FacultyUsers {
	########
	#				       	
	# 	Pay attention to variables		
	#            						
	#	You can alter the parameters 		
	#	(description,etc)			
	#  						
	#  	You can alter the groups array 		
	#						
	#   	As noted, the output CSV will 			
	#	be in the directory where you		
	#	saved the input CSV
	#  						
	#########

	$continue = "n"
	write-host ""
	write-host "CSV should contain: lastname,firstname,rnumber,office -- Continue? y/n" -foregroundcolor red -backgroundcolor yellow
	$continue = read-host 
	write-host ""
	$continue = $continue.substring(0,1).tolower()

	if ($continue -ne "y")  {"Thanks for playing."; exit}
		###start in the current directory
		$dir = $psscriptroot
		$date = get-date -format MM-dd-yyyy

		
		$csvIn = get-filename "c:\"
		$names = import-csv $csvIn
		
		###process each line in the array
		foreach ($name in $names) 
		{

			###generate a random 6 character password as a string
			$password = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})

			###check for existing username--up to 5 iterations of duplicate usernames
			$unamechk = "$($name.last)$($name.first[0])".tolower()
			$exit = 0
			$count = 1
			do 
			{
				Try
				{
					#see if the user already exists
					$user = get-aduser -identity $unamechk
					$count = $count + 1
					$unamechk = $unamechk + $count
						if ($count -gt 5) {$exit = 1}

				}
				Catch
				{
					$exit = 1
				}
			}
			While ($Exit -eq 0)

			###set the parameters for the new user
			$params =@{
				displayname = "$($name.last)_$($name.first)"
				givenname = $name.first
				surname = $name.last
				name = $unamechk
				samaccountname = $unamechk
				office = $name.office
				employeeID = $name.rnumber
				employeeNumber = $name.rnumber
				email = "$unamechk@rhodes.edu".tolower()
				description = "Faculty"
				path = "CN=Users,DC=rhodes,DC=edu"
				accountpassword = (convertto-securestring "$password" -asplaintext -force)
				enabled = $true
				changepasswordatlogon = $false
				userprincipalname = "$unamechk@rhodes.edu".tolower()
			}

			###create the user
			New-ADUser @Params

			###add user to groups
			$groups = "box","boxfirsttimeuser","expressonelogin","papercutusers","faculty","faculty_dl","facstaff","wireless_faculty","webrequestuser"
			foreach ($group in $groups) 
			{
			add-adgroupmember -identity $group -members $params.samaccountname
			}
			
			write-host "Account created for: $params.displayname - $params.userprincipalname"
			
			###write this out to a csv for displayname,username, password
			###
			###--------->>>>>>   NOTE:  The CSV will be in the same directory as the input CSV.
			###
			$csvpath = get-childitem $csvIn
			$csvpath = $csvpath.directory.fullname
			$csv = new-object psobject
			$csv | add-member noteproperty id $params.employeeID
			$csv | add-member noteproperty name $params.displayname
			$csv | add-member noteproperty login $params.userprincipalname
			$csv | add-member noteproperty password $password
			$csv | export-csv -path $dir\FacultyAccounts_CreatedOn_$date.csv -notypeinformation -append
			
	}
		
		write-host "Output saved at $csvpath\FacultyAccounts_CreatedOn_$date.csv"
	
#End Create-FacultyUsers
}