$compName = 'SAMSUNG-LAPMICHAL'

Get-Service -ComputerName SAMSUNG-LAPMICHAL | where Name -Like "*sql*"
Get-Service -ComputerName $compName | where Name -Like "*sql*"

Get-ChildItem VARIABLE:\   #wirtualny dysk ze zmiennymi

Get-ChildItem VARIABLE:\comp*

Get-Command -Noun Variable

Clear-Variable compName
Remove-Variable compName
$compName

New-Variable filterExpression
Set-Variable filterExpression adapter
$filterExpression


Get-Service -ComputerName $compName | where Name -Like "*filterExpresion*"

#jeśli tekst jest w " " PS interpretuje jako wartość lub podstawia wartosc ze zmiennej
#jeśli tekst jest w '' PS nie podmienia zmiennych na wartości

#LAB

$MyService = "bits"
$MyService

Get-Service | where Name -Like "*$MyService*"


New-Variable EventLogName
Set-Variable EventLogName 5

Get-EventLog -Newest $EventLogName


$MyComputerName = 'XXX'
$MyOperatingSystem = 'Win10Pro'
$MyUserName = 'mpasz'


$MyUserName

$env:MyComputerName