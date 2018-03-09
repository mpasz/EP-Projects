Get-WmiObject -Class Win32_operatingSystem -ComputerName GT172,GT173
Get-WmiObject -Class Win32_operatingSystem -ComputerName GT172, GT173 -ErrorAction Stop
Get-WmiObject -Class Win32_operatingSystem -ComputerName GT172, GT173 -ErrorAction SilentlyContinue
Get-WmiObject -Class Win32_operatingSystem -ComputerName GT172, GT173 -ErrorAction Inquire

Get-WmiObject -Class Win32_operatingSystem -ComputerName GT172, GT173 -ErrorAction Ignore
Get-WmiObject -Class Win32_operatingSystem -ComputerName GT172, GT173 -ErrorAction Continue


$ErrorActionPreference