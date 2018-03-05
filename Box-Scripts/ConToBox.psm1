function ConToBox()
{
$code = New-BoxoAuthCode
New-BoxAccessTokens -code $code

write-host ""
write-host "You should run Get-BoxToken and store it in a variable to make things easier for yourself." -ForegroundColor Yellow
write-host ""
write-host ""
}