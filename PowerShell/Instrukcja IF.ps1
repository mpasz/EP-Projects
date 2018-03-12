$letter = 'c:'
$valueToReturn = "TotalSpace"

$valueToReturn

Get-WmiObject  #zwraca informacja o instancjach nazwy klasy podanej po Gwt-WmiObject
Get-WmiObject win32_logicaldisk
Get-WmiObject win32_logicaldisk -Filter "DeviceID = 'c:'"
Get-WmiObject win32_logicaldisk -Filter "DeviceID = '$letter'"

If($valueToReturn -eq "FreeSpace")
{
    Get-WmiObject win32_logicaldisk -Filter "DeviceId - '$letter'" | select FreeSpace
}
elseif ($valueToReturn -eq "TotalSpace") { 
    Get-WmiObject win32_logicaldisk -Filter "DeviceId = '$letter'" | select Size
       
}
else {
    Get-WmiObject win32_logicaldisk -Filter "DeviceId = '$letter'" | select @{n="used";e={$_.Size-$_.FreeSpace}}
}


!!!!!!############LABY DO ZROBIENIA############@!!!!!!

