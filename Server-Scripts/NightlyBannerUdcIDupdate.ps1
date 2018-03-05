#Get a list of users from AD that do not have Banner UDCIDs
$users = get-aduser -filter * -properties employeeNumber, rcBannerUdcid | ? {(-not($_.rcBannerUdcId))}

#For each of those users look up their UDCID and populate it in AD if they have one
$users | foreach-object {
		$id = "'"$_.employeeNumber"'"
		$SQLUDCID = Invoke-Sqlcmd -ServerInstance "DM-2012" -Database "Datamart" -Query "SELECT [SPRIDEN_ID] id,[GOBUMAP_UDC_ID] udcid FROM [dbo].[RC_UDCID] where [SPRIDEN_ID] = '$id'"
		$user.rcBannerUdcid = $SQLUDCID.udcid
		set-aduser -instance $user
	
}