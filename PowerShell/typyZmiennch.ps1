[int]$number = 100
$number
$number = "pierdupierdu"
[datetime]$date = "2018-03-09"
$date
$date.Add(20).DayOfWeek


[bool] $bool = $true

$bool = 0
$bool

[string]$s="Hello"

$s.Contains("He")
$s.IndexOf("l")
$s = "one,two,three,four,five"
$s.Split(",")

$s -is [string]
$s -is [int]

$s = 10  #dlaczego ? napsis wyglądający jak liczba
$s -is [string]

$number = $s   #dlatego bo w tle wykonywana jest konwersja

$number + $s

#TEST + LABO

[string]$logFile = "C:\Moje Dane\Moje\EP-Project\files"
(Get-Date).ToString("yyyy_MM_dd")
$logFile = (Get-Date ).ToString("yyyy_MM_dd_mm_ss")
$logFile

[datetime]$StartTime = Get-Date 
[datetime]$StopTime

Start-Process -FilePath "notepad.exe" -Wait
$StopTime = Get-Date
[timespan]$TimeSpent = $StopTime.Subtract($StartTime)
$TimeSpent.TotalSeconds


