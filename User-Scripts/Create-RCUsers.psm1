
Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
#end Get-FileName
}

Function Create-RCUsers {
	###########################################
	###########################################
	#
	#	This script doesn't take every type of user into account, but it should help for bulk creation of accounts
	#
	#	You should use this function only for accounts that need email. 
	#	Accounts that don't need email can be created using ADUC.
	#
	#	Doug Walker 5/29/2018
	#
	###########################################
	###########################################

	clear
	write-host ""
	write-host ""
	write-host "You should use this function only for accounts that need email." -foregroundcolor red -backgroundcolor yellow
	write-host "Accounts that don't need email can be created using ADUC." -foregroundcolor red -backgroundcolor yellow
	write-host ""
	write-host "CSV should contain: " -nonewline
	write-host "lastname" -foregroundcolor red -nonewline
	write-host "," -nonewline 
	write-host "firstname" -foregroundcolor red -nonewline
	write-host ",middlename,rnumber,office," -nonewline
	write-host "description" -foregroundcolor red -nonewline
	write-host "," -nonewline
	write-host "acctype." -foregroundcolor red
	write-host "(CSV fields in RED are required; headers are required)" 
	write-host ""
	write-host "IMPORTANT:  Make sure you check for spaces, dashes, apostrophes, or other characters that will mess up an email address in the name fields!!!"
	write-host "Continue? y/n" -nonewline -foregroundcolor red -backgroundcolor yellow
	$continue = read-host 
	write-host ""
	$continue = $continue.substring(0,1).tolower()

	if ($continue -ne "y")  {"Thanks for playing.";""; exit}

	Try {
	
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
			
			if ($name.rnumber -ne "")
			{
				$rnum = $name.rnumber
			}else{
				$uTime = [long] (Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)
				$uTime = $name.description.substring(0,1) + $uTime.tostring().substring(1,8)
				$rnum = $uTime
			}

			$cPath = $name.acctype.tolower()
			
			switch ($cPath) {
			
				staff {
				
					$unamechk = "$($name.lastname)$($name.firstname[0])".tolower()
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
				
					$params = @{
						displayname = "$($name.lastname)_$($name.namefirst)"
						givenname = $name.firstname
						surname = $name.lastname
						name = $unamechk
						samaccountname = $unamechk
						office = $name.office
						employeeID = $rnum
						employeeNumber = $rnum
						description = $name.description
						email = "$unamechk@rhodes.edu".tolower()
						path = "CN=Users,DC=rhodes,DC=edu"
						accountpassword = (convertto-securestring "$password" -asplaintext -force)
						enabled = $true
						changepasswordatlogon = $false
						userprincipalname = "$unamechk@rhodes.edu".tolower()
					}
					
					###create the user
					New-ADUser @Params

					$csvpath = get-childitem $csvIn
					$csvpath = $csvpath.directory.fullname
					$csv = new-object psobject
					$csv | add-member noteproperty ID $params.employeeID
					$csv | add-member noteproperty name $params.displayname
					$csv | add-member noteproperty login $params.userprincipalname
					$csv | add-member noteproperty password $password
					$csv | export-csv -path $dir\newaccounts_$date.csv -notypeinformation -append
					
					write-host "Account created for: $name.lastname_$name.firstname - $name.unamechk@rhodes.edu"


					###add user to groups
					$groups = "box","boxfirsttimeuser","expressonelogin","papercutusers","staff","staff_dl","facstaff","wireless_staff"
					foreach ($group in $groups) 
					{
						add-adgroupmember -identity $group -members $params.samaccountname
					}
		#end staff		
				}
				
				faculty {
				
					$unamechk = "$($name.lastname)$($name.firstname[0])".tolower()
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
				
					$params = @{
						displayname = "$($name.lastname)_$($name.firstname)"
						givenname = $name.firstname
						surname = $name.lastname
						name = $unamechk
						samaccountname = $unamechk
						office = $name.office
						employeeID = $rnum
						employeeNumber = $rnum
						description = $name.description
						email = "$unamechk@rhodes.edu".tolower()
						path = "CN=Users,DC=rhodes,DC=edu"
						accountpassword = (convertto-securestring "$password" -asplaintext -force)
						enabled = $true
						changepasswordatlogon = $false
						userprincipalname = "$unamechk@rhodes.edu".tolower()
					}

					###create the user
					New-ADUser @Params
					
					$csvpath = get-childitem $csvIn
					$csvpath = $csvpath.directory.fullname
					$csv = new-object psobject
					$csv | add-member noteproperty id $params.employeeID
					$csv | add-member noteproperty name $params.displayname
					$csv | add-member noteproperty login $params.userprincipalname
					$csv | add-member noteproperty password $password
					$csv | export-csv -path $dir\newaccounts_$date.csv -notypeinformation -append

					write-host "Account created for: $name.lastname_$name.firstname - $name.unamechk@rhodes.edu"
					
					###add user to groups
					$groups = "box","boxfirsttimeuser","expressonelogin","papercutusers","faculty","faculty_dl","facstaff","wireless_faculty"
					foreach ($group in $groups) 
					{
					add-adgroupmember -identity $group -members $params.samaccountname
					}
		#end faculty
				}
				
				student {
					
					if (($name.middlename).length -ne 0) 
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

					$params = @{
						displayname = "$($name.lastname)_$($name.firstname)"
						givenname = $name.firstname
						surname = $name.lastname
						name = $unamechk
						samaccountname = $unamechk
						employeeID = $rnum
						employeeNumber = $rnum
						description = $name.description
						email = "$unamechk@rhodes.edu".tolower()
						path = "OU=Students,DC=rhodes,DC=edu"
						accountpassword = (convertto-securestring "$password" -asplaintext -force)
						enabled = $true
						changepasswordatlogon = $false
						userprincipalname = "$unamechk@rhodes.edu".tolower()
					}
					
					###create the user
					New-ADUser @Params
					
					$csvpath = get-childitem $csvIn
					$csvpath = $csvpath.directory.fullname
					$csv = new-object psobject
					$csv | add-member noteproperty id $params.employeeid
					$csv | add-member noteproperty lastname $params.surname
					$csv | add-member noteproperty firstname $params.givenname
					$csv | add-member noteproperty login $params.userprincipalname
					$csv | add-member noteproperty password $password
					$csv | export-csv -path $csvpath\newaccounts_$year.csv -notypeinformation -append
					
					write-host "Account created for: $name.lastname_$name.firstname - $name.unamechk@rhodes.edu"

					###add user to groups
					$groups = "expressonelogin","papercutusers","students","wireless_students","box","boxfirsttimeuser"
					foreach ($group in $groups) 
						{
						add-adgroupmember -identity $group -members $params.samaccountname
					}
		#end student
				}
				
				vendor {
				
					$unamechk = "$($name.lastname)$($name.firstname[0])".tolower()
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
					
					$params = @{
						displayname = "$($name.lastname)_$($name.firstname)"
						givenname = $name.firstname
						surname = $name.lastname
						name = $unamechk
						samaccountname = $unamechk
						office = $name.office
						employeeID = $rnum
						employeeNumber = $rnum
						description = $name.description
						email = "$unamechk@rhodes.edu".tolower()
						path = "OU=Vendor,DC=rhodes,DC=edu"
						accountpassword = (convertto-securestring "$password" -asplaintext -force)
						enabled = $true
						changepasswordatlogon = $false
						userprincipalname = "$unamechk@rhodes.edu".tolower()
					}
					
					###create the user
					New-ADUser @Params
					
					$csvpath = get-childitem $csvIn
					$csvpath = $csvpath.directory.fullname
					$csv = new-object psobject
					$csv | add-member noteproperty id $params.employeeid
					$csv | add-member noteproperty lastname $params.surname
					$csv | add-member noteproperty firstname $params.givenname
					$csv | add-member noteproperty login $params.userprincipalname
					$csv | add-member noteproperty password $password
					$csv | export-csv -path $csvpath\newaccounts_$year.csv -notypeinformation -append
					
					write-host "Account created for: $name.lastname_$name.firstname - $name.unamechk@rhodes.edu"
					
					
		#end vendor	
				}
				
				temp {
				
					$unamechk = "$($name.lastname)$($name.firstname[0])".tolower()
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
					
					$params = @{
							displayname = "$($name.lastname)_$($name.firstname)"
							givenname = $name.firstname
							surname = $name.lastname
							name = $unamechk
							samaccountname = $unamechk
							office = $name.office
							employeeID = $rnum
							employeeNumber = $rnum
							description = $name.description
							email = "$unamechk@rhodes.edu".tolower()
							path = "OU=Temp Accounts,DC=rhodes,DC=edu"
							accountpassword = (convertto-securestring "$password" -asplaintext -force)
							enabled = $true
							changepasswordatlogon = $false
							userprincipalname = "$unamechk@rhodes.edu".tolower()
						}
						
						
					###create the user
					New-ADUser @Params
					
					$csvpath = get-childitem $csvIn
					$csvpath = $csvpath.directory.fullname
					$csv = new-object psobject
					$csv | add-member noteproperty id $params.employeeid
					$csv | add-member noteproperty lastname $params.surname
					$csv | add-member noteproperty firstname $params.givenname
					$csv | add-member noteproperty login $params.userprincipalname
					$csv | add-member noteproperty password $password
					$csv | export-csv -path $csvpath\newaccounts_$year.csv -notypeinformation -append
					
					write-host "Account created for: $name.lastname_$name.firstname - $name.unamechk@rhodes.edu"

					###add user to groups
					$groups = "expressonelogin","papercutusers","staff","wireless_staff","box","boxfirsttimeuser"
					foreach ($group in $groups) 
						{
						add-adgroupmember -identity $group -members $params.samaccountname
					}
		#end temp		

				}

			}	
		}

			
		write-host "Output saved at $csvpath\newaccounts_$date.csv"
	}
	
	Catch {
	Write-host "What went wrong?"
	}
	

}

