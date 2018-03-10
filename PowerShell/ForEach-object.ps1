Get-ChildItem C:\scripts
Get-ChildItem C:\scripts | Get-Member
Get-ChildItem C:\scripts -Filter "*.csv" | foreach Delete
Get-ChildItem C:\scripts
Get-ChildItem C:\scripts -Filter "*.txt" | foreach {$_.CopyTo('c:\scripts\PS1\'+$_.Name)}

Get-ChildItem C:\scripts\PS1
Get-Process | ForEach -Begin {get-date | Out-File -FilePath 'C:\Scripts\report.txt' -Append} -Process {$_ | select Name, Vm | Out-File 'C:\scripts\report.txt' -Append} -End {'Koniec'| out-file -FilePath C:\scripts\report.txt -Append}
Get-Content C:\scripts\report.txt


#LAB
'wuauserv                bits' |Out-File c:\services.txt
Get-Content c:\services.txt
Get-Content c:\services.txt | foreach {Stop-Service $_}
Get-Content c:\services.txt | foreach -Begin {Write-host -BackgroundColor Yellow "Starting services"} {Write-Host "Starting $_"; Start-Service $_} -End {Write-Host -BackgroundColor Green "Done"}