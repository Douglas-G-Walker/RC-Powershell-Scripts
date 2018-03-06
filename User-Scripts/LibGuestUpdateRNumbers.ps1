####################
####                                                                
####    Update the password and Rnumber for the       
####    library guest accounts so they can log in and print                    
####                                                                                                                               
####    It should run once a week on Saturday at 11:30PM on Utility002
####	Timing is important because Papercut syncs at 00:55 daily and
####	the RNumbers will have to sync for the next day
####                                                                
####    03062018  --- Doug Walker                                   
####                                                                
#####################

import-module ActiveDirectory
$tdate = get-date -format o | foreach {$_ -replace ":", "."}
$tfile = "c:\scripts\logs\LibGuestRNum\$tdate.txt"
Start-Transcript -path $tfile
$outputfile="\\fileserver\FacStaff_Community\Library\Private\LIBGUEST\LibGuestAccounts.txt"

###Delete the existing text file if it exists, recreate it with the datestamp
if (Test-Path $outputfile) {Remove-Item $outputfile}
$date = date
$date = "[Updated on: $date]`r`n--------------------`r`n" | out-file $outputfile -append

###Get the library guest users, I do it this way because we may add more or delete some--this way it gets them all every time
$users = get-aduser -searchbase "OU=Temp Accounts,DC=rhodes,DC=edu" -filter "sAMAccountname -like 'libguest*'" -properties employeeNumber, employeeID

###Process library guest user array
###Set the employeeID and employeeNumber values to a random 7 digit number
$users | foreach-object {
		$password = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})
		$newpass = convertto-securestring $password -asplaintext -force
		$id = get-random -minimum 1000000 -maximum 9999999
		$_.employeeID = $id
		$_.employeeNumber = $id
		set-aduser -instance $_
		$username = $_.sAMAccountname
		set-adaccountpassword $username -newpassword $newpass -reset
		$csvstr = "$username`r`n     Password: $password`r`n     PIN: $id`r`n" | out-file $outputfile -append
}
###TODO
#wipe profiles

stop-transcript



