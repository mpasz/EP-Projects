$emailFrom = "paszmichal@gmail.com"
$emailTo = "michal.pasz@electropoli.pl"
$Subject = "Test email from powershell"
$body = "Test"
$SMTPSeerver = smtp.gmail.com
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPSeerver, 587) 
$SMTPClient.EnableSsl =$true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("magazynpamieci", "CoolPass!");;
$SMTPClient.Send($emailFrom, $emailTo, $Subject , $body)

[CmdletBinding()]