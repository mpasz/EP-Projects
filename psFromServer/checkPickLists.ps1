
 $TASK_PATH = '\'
$TASK_NAME = 'Tworzenie List pobrania'
$task = Get-ScheduledTask -TaskName $TASK_NAME -TaskPath $TASK_PATH 
if($task.State -eq 'Ready'){
    $task | Start-ScheduledTask
} 