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
	write-host "CSV should be in this format:  id,ln,fn,mn ---- Continue? y/n" -foregroundcolor red -backgroundcolor yellow
	$continue = read-host 
	write-host ""
	$continue = $continue.substring(0,1).tolower()
	if ($continue -eq "y") {


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
					#see if the user actually exists
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

			###write this out to a csv for displayname,username, password
			###
			###--------->>>>>>   NOTE:  The CSV will be in the same directory as the input CSV.
			###
			$csvpath = get-childitem $csvIn
			$csvpath = $csvpath.directory.fullname
			$csv = new-object psobject
			$csv | add-member noteproperty name $params.employeeid
			$csv | add-member noteproperty name $params.surname
			$csv | add-member noteproperty name $params.givenname
			$csv | add-member noteproperty login $params.userprincipalname
			$csv | add-member noteproperty password $password
			$csv | export-csv -path $csvpath\writingcampaccounts_$year.csv -notypeinformation -append

			###create the user
			New-ADUser @Params

			###add user to groups
			$groups = "expressonelogin","papercutusers","students","wireless_students","WritingCamp"
			foreach ($group in $groups) 
				{
				add-adgroupmember -identity $group -members $params.samaccountname
				}
		}
		write-host "Output saved at $csvpath\writingcampaccounts_$year.csv"

	}else{
	write-host "Thanks for playing."
	}