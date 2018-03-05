#Box calls the process of removing users from the enterprise "Rolling Out"
#Seems backward, but what are you going to do

#The CSV needs to be in the same directory as this script
$csv = import-csv "GradBoxUserIDs.csv"
$token = Get-BoxToken
foreach ($line in $csv) {RO-BoxUser -id $line.BoxID -token $token}