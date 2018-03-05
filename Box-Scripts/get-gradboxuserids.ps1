$csv = import-csv "emails.csv"
$token= Get-BoxToken
foreach ($line in $csv) {Get-BoxUserID $line.email -token $token | out-file "GradBoxUserIDs.csv" -append}