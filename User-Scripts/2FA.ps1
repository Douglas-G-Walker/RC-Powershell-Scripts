$users = import-csv c:\scripts\2FAUsers.csv
foreach ($user in $users)
{
    $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $st.RelyingParty = "*"
    $st.State = "Disabled"
    $sta = @($st)
    Set-MsolUser -UserPrincipalName $user.username -StrongAuthenticationRequirements $sta
}


#DISABLE:
$users = import-csv c:\scripts\2FAUsers.csv
foreach ($user in $users)
{
    
    $mfa = @()
    Set-MsolUser -UserPrincipalName $user.username -StrongAuthenticationRequirements $mfa
}
