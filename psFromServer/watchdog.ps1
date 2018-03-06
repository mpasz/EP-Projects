$TASK_PATH = '\'
$WATCHDOG_PATH = 'C:\Computec\Powershell\watchdog'

$date = Get-Date
$LogFile = $WATCHDOG_PATH + '\'+[string]$date.Year + "-" + [string]$date.Month +  "-" + [string]$date.Day+'_log.txt'
$watchdogDirectory = Get-Item $WATCHDOG_PATH


$exceededWatchdogFiles = $watchdogDirectory.GetFiles('*.watchdog')  | Where-Object { $_.LastWriteTime -lt ($date).AddSeconds(-60)}


$taskArray = New-Object 'System.Collections.Generic.Dictionary[string,string]'

$taskArray.Add('PickOrderPickReceipt.watchdog','Przyjęcie wydanie do produkcji');

foreach($file in $exceededWatchdogFiles){
    
    $key = $file.Name;
    if($taskArray.ContainsKey($key)){
        $taskName = $taskArray[$key]  
    
        $task = Get-ScheduledTask -TaskName $taskName -TaskPath $TASK_PATH 
        if($task.State -eq 'Running'){
            $msg = [string]::Format('{0} - excedded watchdog file found: {1}. Stoping task: {2}',$date,$key, $taskName);
            Add-Content $LogFile $msg
            $task | Stop-ScheduledTask
            $msg = [string]::Format('{0} - task: {1} stopped',$date, $taskName);
            Remove-Item $file.FullName -ErrorAction Ignore
            Add-Content $LogFile $msg
        }  
    }
}