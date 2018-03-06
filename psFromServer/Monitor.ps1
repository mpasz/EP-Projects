$TASK_PATH = '\'

$TASK_NAMES = @('Lista pobrania','Przyjęcie Wydanie do produkcji','Zlecenia nie planowane','Zlecenie wysyłki','Przesunięcie na izolator','RW do PDW','RWPW','Zlecenia nieplanowane z dokumentu PZ','Zlecenia nieplanowane z dokumentu PW','Tworzenie żądań przesunięć magazynowych','Zamykanie zlecen produkcyjnych','KalkulacjaOferta','Wycofywanie Partii na ZS')
#$TASK_NAMES = @('Lista pobrania','Przyjęcie Wydanie do produkcji','Zlecenia nie planowane','Zlecenie wysyłki','Przesunięcie na izolator','RW do PDW','RWPW','Zlecenia nieplanowane z dokumentu PZ','Zlecenia nieplanowane z dokumentu PW')
foreach($TASK_NAME in $TASK_NAMES){

    $task = Get-ScheduledTask -TaskName $TASK_NAME -TaskPath $TASK_PATH 
    if($task.State -eq 'Ready'){
        $task | Start-ScheduledTask
    }  
}




