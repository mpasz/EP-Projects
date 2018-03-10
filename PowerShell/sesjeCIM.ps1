$s=New-CimSession -ComputerName SAMSUNG-LAPMICHAL

Get-CimInstance -ClassName Win32_LogicalDisk -CimSession $s


$Option = New-CimSessionOption -Protocol DCOM
$s2 = New-CimSession -ComputerName SAMSUNG-LAPMICHAL -SessionOption $option

$s2
$s

Get-CimSession

Get-CimSession | Remove-CimSession

$env:COMPUTERNAME


$session = New-CimSession -ComputerName $env:COMPUTERNAME
