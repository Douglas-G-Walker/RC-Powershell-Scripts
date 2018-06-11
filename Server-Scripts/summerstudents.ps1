$students = Invoke-SqlCmd -ServerInstance "DM-2018" -Database "Datamart" -Query "SELECT REPLACE (email_address, '@rhodes.edu', '') as email FROM [dbo].[Summer Student Distribution List for AD (Descriptive, Student)]"
$members = Get-ADGroupMember -Identity "SummerStudents" -Recursive | Select -ExpandProperty Name
foreach ($student in $students) {
    if ($members -notcontains $student.email) {
	   add-adgroupmember -identity "SummerStudents" -members $student.email
    }
}

foreach ($member in $members){
  if ($students -notcontains $member.name) {
    remove-adgroupmember -identity "SummerStudents" -members $member.distinguishedname
  }


 }
