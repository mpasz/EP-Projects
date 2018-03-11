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


############LABY DO ZROBIENIA############!!!!!!
#1 
Test-Connection SAMSUNG-LAPMICHAL 
Test-Connection GT173 ,GT136 -Count 1 -Quiet # sprawdza połączenie i zwraca True/false a opcja quiet w przypadku błędu nie wyświetla go
$Destination = "C:\EP-Projects\EP-Projects\psFromServer"

$isAlive = Test-Connection GT173  -Count 1 -Quiet



if ($isAlive -eq 'True')
{
     Write-Host "Copying files to $Destination  " | Copy-Item "C:\EP-Projects\EP-Projects\files\test.txt" -Destination $Destination
}else
{
    Write-Host "Remote host is not responding"
}







