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
#	saved the script itself.		
#  						
#########


$year = get-date -f yyyy
###start in the current directory
$dir = $psscriptroot

###read the csv of users in an array
$names = read-host "Where's the CSV?"
$names = import-csv $names

###process each line in the array
foreach ($name in $names) {

###generate a random 6 character password as a string
$password = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})
	
###check for existing username--up to 5 iterations of duplicate usernames
$unamechk = "$($name.last)$($name.first[0])".tolower()
$exit = 0
$count = 1
do {
	Try{
		#see if the user actually exists
		$user = get-aduser -identity $unamechk
		$count = $count + 1
		$unamechk = $unamechk + $count
			if ($count -gt 5) {$exit = 1}

		}
	Catch{
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
	description = "Lausanne Student $year"
	path = "OU=Temp Accounts,DC=rhodes,DC=edu"
	accountpassword = (convertto-securestring "$password" -asplaintext -force)
	enabled = $true
	changepasswordatlogon = $false
	userprincipalname = "$unamechk@rhodes.edu".tolower()
}

###write this out to a csv for displayname,username, password
###
###--------->>>>>>   NOTE:  THIS CSV WILL BE IN THE DIRECTORY IN WHICH YOU SAVED THE SCRIPT!!!!
###
$csv = new-object psobject
$csv | add-member noteproperty name $params.displayname
$csv | add-member noteproperty login $params.userprincipalname
$csv | add-member noteproperty password $password
$csv | export-csv -path $dir\lausanneaccounts.csv -notypeinformation -append

###create the user
New-ADUser @Params

###add user to groups
$groups = "expressonelogin","papercutusers","students","wireless_students"
foreach ($group in $groups) {
add-adgroupmember -identity $group -members $params.samaccountname
	}

}