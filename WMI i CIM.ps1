Get-WmiObject -Namespace root\CIMv2 -List -Recurse | Select -Unique __NAMESPACE
Get-WmiObject -Namespace root\CIMv2 -List -Recurse | Where {$_.Name -like "*desktop*"}
Get-WmiObject -Namespace root\CIMv2 -List -Recurse | Where {$_.Name -like "*desktop*"} | sort Name

Get-WmiObject -Class Win32_Desktop
Get-WmiObject -Class Win32_LogicalDisk

Get-CimInstance -ClassName Win32_Desktop
Get-CimInstance -ClassName Win32_LogicalDisk

#klasa to np dysk logiczny
#obiekt dysku logicznego to konkretny dysk logiczny np C

Get-WmiObject -Query "Select * from Win32_LogicalDisk"
Get-CimInstance -query "Select * from Win32_LogicalDisk"

Get-CimInstance -ClassName Win32_process -Filter "Name = 'notepad.exe'"
Get-WmiObject -query "select * from Win32_Process where Name = 'notepad.exe'"


####LAB#######
Get-WmiObject -query "select * from "

Get-WmiObject -Namespace root\CIMv2 | where {$_.Name -like "*network*"}
Get-CIM -Namespace root\CIMv2 | where {$_.Name -like "*network*"}
