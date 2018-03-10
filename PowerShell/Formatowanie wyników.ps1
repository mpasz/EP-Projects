Get-EventLog Security -Newest 10
Get-Service | Format-Wide
Get-Service | FW
Get-Service | FW -Property ServiceName
Get-Service | FW -Property DisplayName
Get-Service | FW -Column 5
Get-Service | FW -AutoSize

Get-Service | Format-List
Get-Service | FL
Get-Service | FL -Property *
Get-Service | FL -Property Name,Status



Get-Service | Format-Table
Get-Service | FT
Get-Service | FT Name, Status, DisplayName,ServiceType -AutoSize -Wrap
ls C:\scripts | FT name, @{n="Size in KB"; e={$_.Length/1KB}}
ls C:\scripts | FT name, @{n="Size in KB"; e={$_.Length/1KB};formatstring = "N2"}
ls C:\scripts | FT name, @{n="Size in KB"; e={$_.Length/1KB};formatstring = "N2"} -AutoSize

Get-Service | FT
Get-Service |Sort Status | FT 
Get-Service |Sort Status | FT |Get-Member



Get-Service |Sort Status | select Status, Name, DisplayName

Get-Service | FT -GroupBy Status
Get-Service | Sort Status | FT -GroupBy Status
Get-Service | Group-Object Status

Get-Service | select Status,Name,DisplayName | ConvertTo-Html | Out-File C:\temp\service.html
Invoke-Item C:\temp\service.html
Get-Service | Out-GridView


#####LAB#####
#1
Get-WmiObject -Class Win32_Desktop
#2
Get-WmiObject -Class Win32_Desktop | Format-Wide
#3
Get-WmiObject -Class Win32_Desktop | FW -Column 3
#4
Get-WmiObject -Class Win32_Desktop | Format-Table
#5
Get-WmiObject -Class Win32_Desktop | Format-List
#6
Get-WmiObject -Class Win32_Desktop | FT -Property *
Get-WmiObject -Class Win32_Desktop | FT -Property Name,ScreenSaverActive
#7
Get-WmiObject -Class Win32_Desktop | Out-GridView