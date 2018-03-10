Get-Service | Out-File C:\scripts\services.txt
Get-Content C:\scripts\services.txt

Get-Service | Out-GridView

Get-Service | Get-Member

Get-ChildItem C:\scripts | Get-Member | Out-GridView

Get-ChildItem  C:\scripts 

##LAB
#1
Get-Command *prin*
#2
Get-Printer
#3
$printerName = Get-Printer -Name 'Microsoft Print to PDF'
#4
'Hello World' | Out-Printer $printerName
#5
Get-PrintJob $printerName
#6
Get-PrintJob $printerName | Out-File C:\scripts\printerJobs.txt
#7
Get-PrintJob $printerName | Out-GridView
#8
Get-PrintJob $printerName | Get-Member
#9
Get-Printer 'Microsoft Print to PDF' | Get-Member -MemberType Properties
#10
Get-PrintJob 'Microsoft Print to PDF' -ID 8
#11
Remove-PrintJob  'Microsoft Print to PDF' -ID 8  
Get-PrintJob 'Microsoft Print to PDF' -ID 8
#12
Remove-PrintJob  'Microsoft Print to PDF' 





#lekcja 2 SortObject


Get-Service | Sort-Object -Property Name
Get-Service | Sort Name
Get-Service | sort Status , Name
Get-Process | Get-Member | Sort Name
Get-Process | Sort VS -Descending
Get-EventLog -LogName Security | Sort-Object -Property TimeWritten -Descending

get-service | sort status,name


#LAB####

Get-Process 
Get-Process | Sort CPU 
Get-Process | Sort CPU -Descending
Get-Process | Sort Name, CPU
Get-Process | Get-Member   #System.Object CPU {get=$this.TotalProcessorTime.TotalSeconds;}   #


Get-Process | Sort-Object -Property TotalProcessorTime -Descending


####lekcja 3 Measure objects
1,2,3,4,5,6 | Measure-Object
1,2,3,4,5,6 | Measure-Object -Sum -Average -Minimum
Get-ChildItem C:\scripts | Measure-Object -Property Length -Sum
Get-ChildItem C:\scripts | Get-Member 

Get-Command *HotFix*
Get-HotFix |Measure
Get-ChildItem Cert:\LocalMachine -Recurse
Get-ChildItem Cert:\LocalMachine | measure 
Get-ChildItem Cert:\LocalMachine -Recurse | Measure-Object -Property NotAfter -Minimum 
ls -Recurse C:\Windows | measure -Property Length -Minimum
ls -Recurse C:\Windows | measure -Property Length -Ma




