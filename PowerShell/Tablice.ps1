Get-Content 'C:\Moje Dane\Moje\EP-Project\files\compNames.txt'
$compNames = Get-Content 'C:\Moje Dane\Moje\EP-Project\files\compNames.txt'
$compNames

$compNames | ForEach-Object {"Working on $_"}
$compNames | ForEach-Object {Get-Content "C:\Moje Dane\Moje\EP-Project\files\$_.txt"}

$compNames[0]
$compNames[1]
$compNames.Count

$compNames[0].Length
$compNames[-1]
$compNames[-2]
$compNames[11]
$services = Get-Service
$services.Count

$runningServices = Get-Service | where {$_.Status -eq "Running"}
$runningServices.Count
$runningServices.Length

$services.Count - $runningServices.Count





#LAB zmienne tablicowe
$certs = Get-ChildItem Cert:\LocalMachine\CA
$certs | ForEach-Object {$_.Thumbprint+""+$_.Verify()}


$subDirs = "01_Input", "02_Processing","03_Results"
$subDirs
$baseDir = 'C:\Moje Dane\Moje\EP-Project\files\'
$baseDir

$subDirs | ForEach-Object {Write-Host $_}
$subDirs | ForEach-Object {$baseDir+""+$_}
$subDirs | ForEach-Object {Write-Host "$baseDir$_"}

$subDirs | ForEach-Object {New-Item -Path "$baseDir$_" -ItemType Directory}  #tworzy pilk w cieżce ze zmiennej

$subDirs | Out-File "$baseDir\test.txt"
Get-Content "$baseDir\test.txt"

Get-Content -Path "$baseDir\test.txt" | ForEach-Object{Write-Host "$baseDir$_"} #zamienia potok tak żeby czytac nazwy folderów z pliku test.txt

notepad.exe "$baseDir\test.txt"

Get-Content -Path "$baseDir\test.txt" | ForEach-Object {New-Item -Path "$baseDir$_" -ItemType Directory}







