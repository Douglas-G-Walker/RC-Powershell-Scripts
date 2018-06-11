###### This script is a part of the RC-Utils module.  You can use it as a one-off, but if you import the module into your powersehell profile you can just type the name of the function.
###### 
###### Import-Module PATHTOMODULE\RC-Utils.psm1

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

if ($continue -eq "y") 
{
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
				#see if the user actually exists
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
		$params = @
		{
			displayname = "$($name.last)_$($name.first)"
			givenname = $name.first
			surname = $name.last
			name = $unamechk
			samaccountname = $unamechk
			physicaldeliveryofficename = $name.office
			employeeID = $name.rnumber
			employeeNumber = $name.rnumber
			description = "Staff"
			path = "CN=Users,DC=rhodes,DC=edu"
			accountpassword = (convertto-securestring "$password" -asplaintext -force)
			enabled = $true
			changepasswordatlogon = $false
			userprincipalname = "$unamechk@rhodes.edu".tolower()
		}
	}

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

	###create the user
	New-ADUser @Params

	###add user to groups
	$groups = "box","boxfirsttimeuser","expressonelogin","papercutusers","staff","staff_dl","facstaff","wireless_staff","webrequestuser"
	foreach ($group in $groups) 
	{
		add-adgroupmember -identity $group -members $params.samaccountname
	}
	write-host "Output saved at $csvpath\StaffAccounts_CreatedOn_$date.csv"
}else{
write-host "Thanks for playing."
}