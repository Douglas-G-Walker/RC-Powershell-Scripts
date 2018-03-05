$users = import-csv c:\scripts\2FAUsers.csv
foreach ($user in $users)
{
    $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $st.RelyingParty = "*"
    $st.State = “Enabled”
    $sta = @($st)
    Set-MsolUser -UserPrincipalName $user.username -StrongAuthenticationRequirements $sta
}