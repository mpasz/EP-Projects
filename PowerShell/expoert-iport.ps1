Get-Help -Verb ConvertTo
Get-Help -verb ConvertFrom

get-help -verb Export
get-help -verb Import

Get-Service | Select-Object -First 5 | ConvertTo-Csv
Get-Service | Select-Object -First 5 | ConvertTo-Csv | ConvertFrom-Csv | Sort Name -Descending | select name,status
Get-Service | Select-Object -First 5 | ConvertTo-Csv | Out-File C:\scripts\services.csv

Get-Content C:\scripts\services.csv
Get-Content C:\scripts\services.csv | ConvertFrom-Csv
Get-Content C:\scripts\services.csv | ConvertFrom-Csv | Get-Member
Import-Csv C:\scripts\services.csv 

Get-Service | Select-Object -Property name -First 5 | ConvertTo-Csv | Out-File C:\scripts\srv.csv
Get-Content C:\scripts\srv.csv
Import-Csv C:\scripts\srv.csv 
Import-Csv C:\scripts\srv.csv | Get-Member

Get-Service | Select-Object -First 5 | Export-Csv C:\scripts\srv.csv
Get-Content C:\scripts\srv.csv
Import-Csv C:\scripts\srv.csv


#LAB

ls C:\Windows |ConvertTo-Html | Out-File C:\scripts\converted.html
Get-Volume -DriveLetter C | Select-Object DriveLetter, Size, SizeRemaining

Get-Volume -DriveLetter C | Select-Object DriveLetter, Size, SizeRemaining | Export-Csv C:\scripts\report.csv -Append
Import-Csv C:\scripts\report.csv
Get-Volume -DriveLetter C | Select-Object DriveLetter, Size, SizeRemaining, @{name='CurretDate';expression= {Get-Date}} | Export-Csv C:\scripts\report-data.csv
Import-csv C:\scripts\report-data.csv
Import-csv  C:\scripts\report-data.csv | Select-Object -Last 0



