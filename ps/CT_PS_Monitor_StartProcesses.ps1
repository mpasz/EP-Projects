[XML]$xml = Get-Content -Encoding UTF8 $PSScriptRoot\CT_PS_Monitor.xml

$secondsBetweenChecks = [int] $xml.PowerShell.scripts.Attributes['secondsBetweenChecks'].Value
$scripts = $xml.PowerShell.scripts.ChildNodes

While($true) {
    
    $date = Get-Date
    Write-Host Get-Date 'Checking' $date

    foreach($script in $scripts){
        $scriptPath = $script.path;
        $windowStyle = $script.windowStyle
        $active = $script.active
        if($active -eq 1){
            $processes = Get-WmiObject Win32_Process -Filter "name = 'powershell.exe'"  | select name, commandline | Where {$_.name -eq 'powershell.exe' -and $_.commandline -like "*$scriptPath*"   } 
            if($processes.Count -eq 0){
                Start-Process -WindowStyle $windowStyle  powershell.exe $scriptPath 
                Write-Host 'Script ' $scriptPath 'started'
            }

        }

    }


    Write-Host 'Completed' 
    Start-Sleep -Seconds $secondsBetweenChecks 
}