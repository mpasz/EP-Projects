Get-Help *computername* -ShowWindow
Get-ComputerInfo

"SAMSUNG-LAPMICH" | Out-File C:\scripts\computername.txt
Get-Content C:\scripts\computername.txt
Get-Content C:\scripts\computername.txt | Get-Process
Get-Help Get-Process -ShowWindow
Get-Content C:\scripts\computername.txt | select @{name = "ComputerName"; expression={$_}} | Get-Process
Get-Process -ComputerName (Get-Content C:\scripts\computername.txt)

"winlogon"  | Out-File C:\scripts\processes.txt
Get-Content C:\scripts\processes.txt | select @{n= "Name" ; e={$_}} | Get-Process
Get-Process -Name (Get-Content C:\scripts\processes.txt)


notepad
Get-Process -Name notepad
Get-Process -Name notepad |Get-Member
Get-Help Stop-Process -ShowWindow
Get-Process -Name notepad | Stop-Process
"notepad" | Out-File C:\scripts\proces_to_stop.txt
Get-Content C:\scripts\proces_to_stop.txt
notepad
Get-Content C:\scripts\proces_to_stop.txt | Stop-Process
Get-Help Stop-Process -ShowWindow
Get-Content C:\scripts\proces_to_stop.txt | select @{n="Name"; e={$_}} | Stop-Process
notepad
Stop-Process -Name (Get-Content C:\scripts\proces_to_stop.txt)

#LAB
#1.
Get-Volume
#2.
Get-Help  Get-Volume -ShowWindow
Get-Volume |select @{n="LiteraDysku"; e={$_.DriveLetter -eq 'C'}}
#3,4
'C' | select @{n="DriveLetter"; e={$_}} | Get-Volume
#5
'C' | foreach {Get-Volume -DriveLetter $_}






