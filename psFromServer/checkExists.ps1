
 $TASK_PATH = '\'
$TASK_NAME = 'Zlecenia nie planowane'
$task = Get-ScheduledTask -TaskName $TASK_NAME -TaskPath $TASK_PATH 
if($task.State -eq 'Ready'){
    $task | Start-ScheduledTask
}  
