10 -gt 5   # większe niż 
10 -eq 9   # równe
10 -lt 11  # mniejsze
10 -ge 10  # większa lub równa oddrugiej
10 -le 10  # mniejsza lub równa
10 -ne 11  # liczny nie są równe

'powershell' -like 'Power*'
'powershell' -clike 'Power*' # z uwzględnieniem wielkości liter
-not $true
1 -eq 1 -and 2 -eq 2
-not (1 -eq 1)

Get-ChildItem C:\scripts | Get-Member
Get-ChildItem C:\scripts | Where-Object -Property PSIsContainter -EQ -value $true
Get-ChildItem C:\scripts | where PSIsContainer -eq $true
Get-ChildItem C:\scripts | where PSIsContainer 
Get-ChildItem C:\scripts | where PSIsContainer -eq $false -and Extension -eq ".txt"
Get-ChildItem C:\scripts | where -FilterScript {$_.PSIsContainer -eq $false -and $_.Extension -eq '.txt'}
Get-ChildItem C:\scripts -Filter "*.txt" -File


#LAB
ls C:\temp | where {$_.LastWriteTime -lt (get-date).AddMinutes(-5) } 
ls C:\temp | where {$_.LastWriteTime -lt (get-date).AddDays(-2) -and $_.Extension -like '.txt'}
notepad; notepad; notepad;
Get-Process
Get-Process -Name '*notepad*'   #lub
Get-Process | where {$_.Name -like '*notepad*'}

Get-EventLog | where {$_.Source - "USER32" -and $_.EventID -eq 1074}





