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
}