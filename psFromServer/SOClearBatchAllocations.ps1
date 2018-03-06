function SOClearBatchAllocations($Company) {

    $lErrCode = 0
    $sErrMsg = ""

    $SQL_ORDERS_BATCHES_ALLOCATION_LIST = "WITH CTE AS (
SELECT
 T1.""DocEntry"", T1.""LineNum"", T1.""ItemCode"", T3.""SysNumber"", T4.""DistNumber"", SUM(T3.""AllocQty"")
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0.""DocEntry"" = T1.""DocEntry"" AND T1.""LineStatus"" = 'O'
 INNER JOIN OITL T2 ON T1.""DocEntry"" = T2.""DocEntry"" AND T1.""LineNum"" = T2.""DocLine"" AND T2.""DocType"" = 17
 INNER JOIN ITL1 T3 ON T2.""LogEntry"" = T3.""LogEntry""
 INNER JOIN OBTN T4 ON T3.""ItemCode"" = T4.""ItemCode"" AND T3.""SysNumber"" = T4.""SysNumber""
WHERE T0.""DocStatus"" = 'O' and T4.""Quantity"" > 0
GROUP BY T1.""DocEntry"", T1.""LineNum"", T1.""ItemCode"", T3.""SysNumber"", T4.""DistNumber""
HAVING SUM(T3.""AllocQty"") <> 0
),

CTE1 AS (
SELECT 
 --T0.""AbsEntry"", 
 T0.""Status"", T0.""Canceled"", T1.""PickStatus"", T1.""OrderEntry"", T1.""OrderLine"",
 T3.""SysNumber"", T3.""DistNumber"", T2.""RelQtty"" + T2.""PickQtty"" AS ""AllocQty""
FROM OPKL T0
 INNER JOIN PKL1 T1 ON T0.""AbsEntry"" = T1.""AbsEntry""
 INNER JOIN PKL2 T2 ON T1.""AbsEntry"" = T2.""AbsEntry"" AND T1.""PickEntry"" = T2.""PickEntry""
 INNER JOIN OBTN T3 ON T2.""SnBEntry"" = T3.""AbsEntry""
WHERE T0.""Status"" = 'C'
)

SELECT DISTINCT
 *
FROM CTE T0
 INNER JOIN CTE1 T1 ON T0.""DocEntry"" = T1.""OrderEntry"" AND T0.""LineNum"" = T1.""OrderLine"" AND T0.""DistNumber"" = T1.""DistNumber""";
   
    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
    VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),'{0}','{1}','{2}','{3}',CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'SOClearBatchAllocations.ps1','F')";
    try {  
        Write-Host -BackgroundColor Green 'Connection successful'
        $recordSetLog = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSet = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSet.DoQuery($SQL_ORDERS_BATCHES_ALLOCATION_LIST);
        $ppPositionsCount = $recordSet.RecordCount
        if ($ppPositionsCount -gt 0) {
            $msg = [string]::format('Pozycji do aktualizacji: {0}', $ppPositionsCount)
            Write-Host -BackgroundColor Blue $msg
            $dictionaryOrder = New-Object 'System.Collections.Generic.Dictionary[int,psobject]'
            Write-Host 'Przygotowywanie danych o pozycjach do pobrania'
            while (!$recordSet.EoF) {
                $orderEntry = $recordSet.Fields.Item('OrderEntry').Value;
                $lineNum = $recordSet.Fields.Item('OrderLine').Value;
                $distNumber = $recordSet.Fields.Item('DistNumber').Value;
                $quantity = $recordSet.Fields.Item('AllocQty').Value;
                    

                $key = $orderEntry;
                
                if ($dictionaryOrder.ContainsKey($key)) {
                    $dictionaryOrderLines = $dictionaryOrder[$key];
                }
                else {
                    $dictionaryOrderLines = New-Object 'System.Collections.Generic.Dictionary[int, psobject]';
                    $dictionaryOrder[$key] = $dictionaryOrderLines;
                }

                if ($dictionaryOrderLines.ContainsKey($lineNum)) {
                    $dictionaryBatches = $dictionaryOrderLines[$lineNum];
                }
                else {
                    $dictionaryBatches = New-Object 'System.Collections.Generic.Dictionary[string, psobject]';
                    $dictionaryOrderLines[$lineNum] = $dictionaryBatches;
                }

                if ($dictionaryBatches.ContainsKey($distNumber)) {
                    $batchObject = $dictionaryBatches[$distNumber];
                    $batchObject.quantity += quantity
                }
                else {
                    $batchObject = [psobject]@{
                        orderEntry = $docEntry
                        lineNum    = $lineNum
                        distNumber = $distNumber
                        quantity   = $quantity
                    };
                    $dictionaryBatches[$distNumber] = $batchObject;
                }
                $recordSet.MoveNext();
            }
        
            #Czyszczenie 
            try {
                #Aktualizacja zleceń - partie
                Write-Host 'Aktualizacja zleceń'
                foreach ($docEntry in $dictionaryOrder.Keys) {
                    try {
                        $order = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oOrders);
                
                        $x = $order.GetByKey($docEntry);

                        $orderLines = $dictionaryOrder[$docEntry]

                        foreach ($rowNum in $orderLines.Keys) {

                            $sapOrderLinesCount = $order.Lines.Count();
                            for($lineIterrator=0;$lineIterrator -lt $sapOrderLinesCount;$lineIterrator++){
                                $order.Lines.SetCurrentLine($lineIterrator);  
                                if($order.Lines.LineNum -eq $rowNum){
                                    break;
                                }
                            }

                            if($order.Lines.LineNum -ne $rowNum){
                                throw [string]::Format("Line {0} in order {1} not found",$rowNum, $docEntry);
                            }
                            
                            
                            #$order.Lines.SetCurrentLine($rowNum);
                            $batchesForOrderLine = $orderLines[$rowNum]
                            foreach ($distNumber in $batchesForOrderLine.Keys) {
                                $batchObject = $batchesForOrderLine[$distNumber];
                                $countBatchNumbersForLine = $order.Lines.BatchNumbers.Count;
                                $order.Lines.BatchNumbers.SetCurrentLine($b);
                                if ($order.Lines.BatchNumbers.BatchNumber -eq $distNumber) {
                                    if ($order.Lines.BatchNumbers.Quantity -lt $batchObject.quantity) {
                                        $order.Lines.BatchNumbers.Quantity = 0
                                    }
                                    else {
                                        $order.Lines.BatchNumbers.Quantity -= $batchObject.quantity;
                                    }
                                    break;
                                }
                            }

                       
                        }

                        $message = $order.Update();
                    
                        if ($message -lt 0) {
                            $err = $Company.GetLastErrorDescription();
                            $ms = [string]::Format("Zlecenie sprzedaży {0} nie zostało zaktualizowane`n`nSzczegóły: {1}", $order.DocNum, $err); 
                            # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                            $logQuery = [string]::Format($SQL_INSERT_LOG, [SAPbobsCOM.BoObjectTypes]::oOrders, 'DocEntry', $order.DocEntry, $ms);
                            $recordSetLog.DoQuery($logQuery);
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            Start-Sleep -Seconds 5
                            continue;
                        } 
                    }
                    Catch {
                        $err = $_.Exception.Message;
                        $ms = [string]::Format("Zlecenie sprzedaży {0} nie zostało zaktualizowane`n`nSzczegóły: {1}", $order.DocNum, $err); 
                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                        $logQuery = [string]::Format($SQL_INSERT_LOG, [SAPbobsCOM.BoObjectTypes]::oOrders, 'DocEntry', $order.DocEntry, $ms);
                        $recordSetLog.DoQuery($logQuery);
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        continue;
                    } finally {
                        $dummy = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($order);
                    }
                }
            }
            Catch {
                $err = $_.Exception.Message;
                $ms = [string]::Format("Zlecenie sprzedaży {0} nie zostało zaktualizowane`n`nSzczegóły: {1}", $order.DocNum, $err); 
                # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                $logQuery = [string]::Format($SQL_INSERT_LOG, [SAPbobsCOM.BoObjectTypes]::oOrders, 'DocEntry', $order.DocEntry, $ms);
                $recordSetLog.DoQuery($logQuery);
                Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                continue;
            } 
           
        }
        else {
            Start-Sleep -Seconds 10
        }
    }
    catch {
        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
        $err = $_.Exception.Message;
        $logQuery = [string]::Format($SQL_INSERT_LOG, '', '', '', $err);
        $recordSetLog.DoQuery($logQuery);
        

    } finally {
        $dummy = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($recordSet);
        $dummy = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($recordSetLog);
    }
}
