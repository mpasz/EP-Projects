[XML]$xml = Get-Content -Encoding UTF8 $PSScriptRoot\CT_PS_Monitor.xml

$scripts = $xml.PowerShell.scripts.ChildNodes

Write-Host 'Closing scripts' 

foreach($script in $scripts){
    $scriptPath = $script.path;
    $windowStyle = $script.windowStyle
    $active = $script.active
    if($active -eq 1){
        $processes = Get-WmiObject Win32_Process -Filter "name = 'powershell.exe'"  | select name, commandline, ProcessId | Where {$_.name -eq 'powershell.exe' -and $_.commandline -like "*$scriptPath*"   } 
        if($processes.Count -ne 0){
            foreach($process in $processes)
            {
                Stop-Process -Id $process.ProcessId 
                Write-Host 'Script ' $scriptPath 'closed'
            }
                
        }

    }

}


Write-Host 'Completed' 