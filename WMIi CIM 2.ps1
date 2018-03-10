Get-WmiObject -Class Win32_OperatingSystem | Get-Member
Get-WmiObject -Class Win32_OperatingSystem | select InstallDate
Get-CimClass -ClassName Win32_OperatingSystem | Get-Member
Get-CimClass -ClassName Win32_OperatingSystem | Select CimClassMethods
Get-CimClass -ClassName Win32_OperatingSystem | Select -ExpandProperty CimClassMethods
Get-CimClass -ClassName Win32_OperatingSystem | Select -ExpandProperty CimClassMethods | where Name -EQ Wind32Shutdown | select -ExpandProperty Parameters

Get-CimClass -ClassName Win32_LogicalDisk | select -ExpandProperty CimClassMethods

Get-WmiObject -Class Win32_Group
Get-CimInstance -ClassName Win32_Group  -Filter "Name = 'IIS_IUSRS'"

Get-CimInstance -ClassName Win32_Group  -Filter "Name = 'IIS_IUSRS'" | 
    Invoke-CimMethod -MethodName Rename -Arguments @{"Name" = "IISIUSRS"}
    
Get-CimInstance -ClassName Win32_Group  -Filter "Name = 'IISIUSRS'" | 
    Invoke-CimMethod -MethodName Rename -Arguments @{"Name" = "IIS_IUSRS"}


    Invoke-CimMethod -Class Win32_Process -MethodName Create -Arguments @{"CommandLine" = "notepad.exe"}
    Get-Process -Name notepad

    Get-CimInstance -ClassName Win32_Process -Filter "Name='notepad.exe'"
    Get-CimInstance -ClassName Win32_Process -Filter "Name='notepad.exe'" | Invoke-CimMethod -MethodName Terminate



#LAB
Get-CimClass -ClassName Win32_NetworkAdapter |Get-Member
Get-CimClass -ClassName Win32_NetworkAdapter |select -ExpandProperty CimSystemProperties
-ExpandProperty CimClassProperties

Get-WmiObject -Class Win32_NetworkAdapter | select -Property Name, Caption ,Description 

Get-WmiObject -Class Win32_NetworkAdapter -Property | Get-Member

Get-WmiObject -Class Win32_NetworkAdapter |Select ServiceName

Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "Name='Microsoft Hosted Network Virtual Adapter'" |
Invoke-CimMethod -MethodName 


Get-WmiObject Win32_NetworkAdapter |where ServiceName -EQ athr | Invoke-WmiMethod -Name Disable
Get-WmiObject Win32_NetworkAdapter |where ServiceName -EQ athr | Invoke-WmiMethod -Name Enable

gwmi Win32_NetworkadapterConfiguration | where DHCPEnabled
gwmi Win32_NetworkadapterConfiguration | where DHCPEnabled | Get-Member
gwmi Win32_NetworkAdapterConfiguration | where DHCPEnabled | Invoke-WmiMethod -Name ReleaseDHCPLease
gwmi Win32_NetworkAdapterConfiguration | where DHCPEnabled | Invoke-WmiMethod -Name RenewDHCPLease









        
