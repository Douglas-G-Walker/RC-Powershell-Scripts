Import-Module ActiveDirectory
Import-Module SQLServer
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

#Start a log file
$date = get-date -format M.d.yyy
$logfile = $date + "_rcBannerUdcid.txt"
$logdir = "c:\scripts\logs\rcBannerUdcid\"
$log = $logdir + $logfile

#Get a list of users from AD that do NOT have Banner UDCIDs
$users = get-aduser -filter * -properties employeeNumber, rcBannerUdcid | ? {(-not($_.rcBannerUdcId))}

#For each of those users look up their UDCID and populate it in AD if they have one
$users | foreach-object {
		$id = $_.EmployeeNumber
		if($id -ne "''") {
			$SQLUDCID = Invoke-Sqlcmd -ServerInstance "DM-2012" -Database "Datamart" -Query "SELECT [SPRIDEN_ID] id,[GOBUMAP_UDC_ID] udcid FROM [dbo].[RC_UDCID] where [SPRIDEN_ID] = '$id'"
			if (($SQLUDCID)) {
			Try {
				$user = get-aduser -filter {employeeNumber -eq $id}
				$user.rcBannerUdcid = $SQLUDCID.udcid
				set-aduser -instance $user
				add-content $log "Processed user: $user"
				}
			Catch {
			add-content "Error: $user $_" >>$log
			}
		}
	}
}

Send-MailMessage -SMTPServer "smtp.rhodes.edu" -To "walkerd@rhodes.edu" -Subject "Banner UDCIDs" -From "NoReply@rhodes.edu" -Body "Banner UDCID script ran.  Check the logs on Utility002 for errors and other good stuff."