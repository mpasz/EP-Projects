$x = 100
$y = 0



try {
    Write-Host "$x / $y" = $($x/$y)    
}
catch {
    Write-Host "Jestes idiotą!!"
    $Error[0]
    "-----------------------" | Out-File 'C:\Moje Dane\Moje\EP-Project\logs\error_log.txt' -Append
    Get-Date | Out-File 'C:\Moje Dane\Moje\EP-Project\logs\error_log.txt' -Append
    $Error[0] | Out-File 'C:\Moje Dane\Moje\EP-Project\logs\error_log.txt' -Append
}

Get-Content 'C:\Moje Dane\Moje\EP-Project\logs\error_log.txt'



#######LAB#####

New-Item -Path "C:\Moje Dane\Moje\EP-Project\logs\temp.txt"

Get-Help "*copy*" -ShowWindow

Copy-Item -Path "C:\Moje Dane\Moje\EP-Project\logs\temp.txt" -Destination \\server01\C$\temp\NewFile.txt

try {
    Copy-Item -Path "C:\Moje Dane\Moje\EP-Project\logs\temp.txt" -Destination  \\server01\C$\temp\NewFile.txt    #C:\Moje Dane\Moje\EP-Project\KopiaTemp.txt"
    Write-Host "File copied"
}
catch {
    Write-Warning "file cannot be copied: $($Error[0].Exception.Message)"   #Write-Host też wyswietli dane ale nie ma odpowiedniego koloru (taka jak Write-Warining)
}
