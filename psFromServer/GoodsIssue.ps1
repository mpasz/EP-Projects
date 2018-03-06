

function createGoodsIssue($Company) {
    $lErrCode = 0
    $sErrMsg = ""

    $SQL_ITEMS = "SELECT
     (SELECT DISTINCT ""Series"" FROM NNM1 TT0 INNER JOIN OFPR TT1 ON TT0.""Indicator"" = TT1.""Indicator"" 
     WHERE ""ObjectCode"" = '60' AND NOW() >= ""F_RefDate"" AND NOW() <= ""T_RefDate"" AND (  
        (T0.""BPLId"" = 1 AND TT0.""SeriesName"" LIKE '%PDWBB%') 
        OR
        (T0.""BPLId"" = 2 AND TT0.""SeriesName"" LIKE '%PDWN%')
       )   ) AS ""Series"",
     T1.""ItemCode"" AS ""ItemCode"",
     CASE T0.""BPLId"" WHEN 1 THEN 'MPR01' WHEN 2 THEN 'MPR01-N' END AS ""WhsCode"",
     SUM(T1.""InvQty"") AS ""Quantity"",
     T0.""DocEntry"" AS ""DocEntry"",
     T0.""BPLId"" AS ""BPLId""
    FROM OPDN T0
     INNER JOIN PDN1 T1 ON T0.""DocEntry"" = T1.""DocEntry""
     INNER JOIN ""@CT_PDW"" T2 ON T0.""DocEntry"" = T2.""U_DocEntryPZ""
     INNER JOIN NNM1 T3 ON T0.""Series"" = T3.""Series""
    WHERE T3.""SeriesName"" LIKE '%PDW%'
    AND IFNULL(T2.""U_DocEntryRW"",0) = 0
    AND T0.""DocEntry"" NOT IN (538,561,566,675,1032) 
    GROUP BY 
     T1.""ItemCode"",
     T1.""WhsCode"",
     T0.""DocEntry"",
     T0.""BPLId""" ;


    $SQLQUERY_BIN_BATCH = "SELECT DISTINCT T2.""ItemCode"", T3.""WhsCode"", T4.""BinAbs"", T2.""DistNumber"", T4.""OnHandQty"" ""Quantity"", T2.""SysNumber""
    FROM OBTN T2
    INNER JOIN OBTQ T3 ON T2.""AbsEntry"" = T3.""MdAbsEntry"" 
    INNER JOIN OBBQ T4 ON T2.""AbsEntry"" = T4.""SnBMDAbs"" AND T3.""WhsCode"" = T4.""WhsCode""
    INNER JOIN OBIN T5 ON T4.""BinAbs"" = T5.""AbsEntry""
    WHERE 
    T4.""OnHandQty"" <> 0
    AND
    T2.""ItemCode"" IN ({0})
      AND T5.""Attr1Val"" LIKE '%POD%' AND T5.""BinCode"" NOT LIKE '%POD%_WYS%'  AND  T3.""WhsCode"" IN ('MPR01','MPR01-N')
    ORDER BY T2.""ItemCode"", T3.""WhsCode"", T2.""SysNumber""";



    $code = $Company.Connected
    if ($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'

        $recordSetItems = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetItems.DoQuery($SQL_ITEMS);
        $ppPositionsCount = $recordSetItems.RecordCount
        
        $msg = [string]::format('Pozycji do wydania: {0}', $ppPositionsCount)
        Write-Host -BackgroundColor Blue $msg
        if ($ppPositionsCount -gt 0 ) {
            $linesDict = New-Object 'System.Collections.Generic.Dictionary[string,psobject]'
        
            Write-Host 'Przygotowywanie danych o pozycjach do wydania'
            while (!$recordSetItems.EoF) {
        
                $Series = $recordSetItems.Fields.Item('Series').Value;
                $ItemCode = $recordSetItems.Fields.Item('ItemCode').Value;
                $WhsCode = $recordSetItems.Fields.Item('WhsCode').Value;
                $Quantity = $recordSetItems.Fields.Item('Quantity').Value;
                $BPLId = $recordSetItems.Fields.Item('BPLId').Value;
                $Udf = $recordSetItems.Fields.Item('DocEntry').Value;

                $key = $BPLId; 

                if ($linesDict.ContainsKey($key)) {
                    $lines = $linesDict[$key];
                }
                else {
                    $lines = New-Object 'System.Collections.Generic.List[psobject]'
                    $linesDict[$key] = $lines;
                }

                $line = [psobject]@{
                    Series   = $Series
                    ItemCode = $ItemCode
                    WhsCode  = $WhsCode
                    Quantity = $Quantity
                    Account  = '999'
                    BPLId    = $BPLId
                    UDF      = $Udf
                };
        
                $lines.Add($line);
                $recordSetItems.MoveNext();
            }

            #Przygotowanie zapytania dla numerów partii
            $sql_param_items_in = "";
        
            $countLines = 0;
            foreach ($key in $linesDict.Keys) {
                $countLines += $linesDict[$key].Count;
            }

            $k = 0;
            foreach ($key in $linesDict.Keys) {
                $lines = $linesDict[$key]               
                foreach ($line in $lines) {
                    $itemCode = $line.ItemCode;
                    $itemCode = $itemCode.Substring(2,$itemCode.Length - 2)
                    $itemCodeSU = 'SU' + $ItemCode;
                    $itemCodeWG = 'WG' + $ItemCode;
                    $sql_param_items_in += "'" + $itemCodeSU + "',";
                    if ($k -eq $countLines - 1 ) {
                        $sql_param_items_in += "'" + $itemCodeWG + "'";
                    }
                    else {
                        $sql_param_items_in += "'" + $itemCodeWG + "',";
                    }

                    $k++;
                }    
            }
            $recordSetBinBatch = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            $query = [string]::Format($SQLQUERY_BIN_BATCH, $sql_param_items_in);
            $recordSetBinBatch.DoQuery($query);

            $prevKey = '';
            $binBatchTable = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[psobject]]';
            $binBatchObjectsList = New-Object 'System.Collections.Generic.List[psobject]'
            
            Write-Host 'Przygtowanie danych o numerach partii oraz lokalizacjach'
            while (!$recordSetBinBatch.EoF) {

                $itemCode = $recordSetBinBatch.Fields.Item('ItemCode').Value;
                $WhsCode = $recordSetBinBatch.Fields.Item('WhsCode').Value;
                $key = $itemCode + '___' + $WhsCode;

                $binBatchObject = [psobject]@{
                    BinAbs     = $recordSetBinBatch.Fields.Item('BinAbs').Value;
                    DistNumber = $recordSetBinBatch.Fields.Item('DistNumber').Value;
                    Quantity   = $recordSetBinBatch.Fields.Item('Quantity').Value;
                    UsedQty    = 0;
                    SimUsedQty    = 0;
                };

                if ($key -ne $prevKey) {
                    if ($prevKey -ne '') {
                        $binBatchTable.Add($prevKey, $binBatchObjectsList);
                    }
                    $binBatchObjectsList = New-Object 'System.Collections.Generic.List[psobject]'
                }

                $binBatchObjectsList.Add($binBatchObject);
            
                $prevKey = $key;
                $recordSetBinBatch.MoveNext();
            }
        
        
            $binBatchTable.Add($prevKey, $binBatchObjectsList);

            foreach ($key in $linesDict.Keys) {
                $lines = $linesDict[$key]  
                try {
                    #Wydanie
                    Write-Host 'Tworzenie dokumentu wydania'
                    $issue = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oInventoryGenExit);
                    $issue.Series = $lines[0].Series
                    $issue.BPL_IDAssignedToInvoice = $lines[0].BPLId
                    # $issue.UserFields.Fields.Item('U_PZPDW').Value = $lines[0].Udf;

                    foreach ($line in $lines) {
            
                        $issueLine = $issue.Lines;
                        $ItemCode = $line.ItemCode;
                        $WhsCode = $line.WhsCode;
                        $Quantity = $line.Quantity;

                        $itemCode = $itemCode.Substring(2,$itemCode.Length - 2)
                        $itemCodeSU = 'SU' + $ItemCode;
                        $itemCodeWG = 'WG' + $ItemCode;

                        $keySU = $itemCodeSU + '___' + $WhsCode;
                        $keyWG = $itemCodeWG + '___' + $WhsCode;

                        $positionsToChooseFromSU = $binBatchTable[$keySU];
                        $positionsToChooseFromWG = $binBatchTable[$keyWG];

                        $issueLineOpenQty = $Quantity;
                        $issueLineAllocatedQty = 0;
                        if ($positionsToChooseFromSU.Count -gt 0) {
                            while ($issueLineAllocatedQty -lt $issueLineOpenQty) {
                                for ($i = 0; $i -lt $positionsToChooseFromSU.Count; $i++) {
                                    $openPosition = $positionsToChooseFromSU[$i];
                                    $openQty = $openPosition.Quantity - $openPosition.SimUsedQty
                                    if ($openQty -gt 0) {
                                        break;
                                    }
                                }

                                if ($openQty -eq 0) {
                                    break;
                                }
                                
                                if ($openQty -ge $issueLineOpenQty) {
                                    $qty = $issueLineOpenQty;
                                }
                                else {
                                    $qty = $openQty;
                                }

                                $issueLineAllocatedQty += $qty;
                                #$issueLineOpenQty -= $qty;
                                $openPosition.SimUsedQty += $qty;
                            }
                        }

                        if($issueLineAllocatedQty -gt 0) {
                            $issueLine.Quantity = $issueLineAllocatedQty;
                            $issueLine.WarehouseCode = $WhsCode;
                            $issueLine.ItemCode = $ItemCodeSU;
                                $issueLine.AccountCode = $line.Account;
                            $issueLine.UserFields.Fields.Item('U_PZPDW').Value = $line.Udf;
                            $issue.Lines.Add();  
                        }
                        if($issueLineAllocatedQty -lt $issueLineOpenQty) {
                            $issueLineAllocatedQtyWG = 0;
                            if ($positionsToChooseFromWG.Count -gt 0) {
                                while ($issueLineAllocatedQty -lt $issueLineOpenQty) {
                                    for ($i = 0; $i -lt $positionsToChooseFromWG.Count; $i++) {
                                        $openPosition = $positionsToChooseFromWG[$i];
                                        $openQty = $openPosition.Quantity - $openPosition.SimUsedQty
                                        if ($openQty -gt 0) {
                                            break;
                                        }
                                    }
    
                                    if ($openQty -eq 0) {
                                        break;
                                    }
                                    
                                    if ($openQty -ge $issueLineOpenQty) {
                                        $qty = $issueLineOpenQty;
                                    }
                                    else {
                                        $qty = $openQty;
                                    }
    
                                    $issueLineAllocatedQty += $qty;
                                    $issueLineAllocatedQtyWG += $qty;
                                   # $issueLineOpenQty -= $qty;
                                    $openPosition.SimUsedQty += $qty;
                                }
                            }
                        }
                        if($issueLineAllocatedQtyWG -gt 0) {
                            $issueLine.Quantity = $issueLineAllocatedQtyWG;
                            $issueLine.WarehouseCode = $WhsCode;
                            $issueLine.ItemCode = $ItemCodeWG;
                                $issueLine.AccountCode = $line.Account;
                            $issueLine.UserFields.Fields.Item('U_PZPDW').Value = $line.Udf;
                            $issue.Lines.Add();  
                        }
                        
                    }

                    $issueLinesCount = $issue.Lines.Count

                    for($lineIndex = 0; $lineIndex -lt $issueLinesCount;$lineIndex++)
                    {

                        $issue.Lines.SetCurrentLine($lineIndex);
                        $issueLine = $issue.Lines;
                        $ItemCode = $issueLine.ItemCode;
                        $WhsCode = $issueLine.WarehouseCode;
                        $Quantity = $issueLine.Quantity;

                        $key = $ItemCode + '___' + $WhsCode;

                        $quantityToBePicked = $Quantity;
                        $pickedQuantity = 0;
                        $positionsToChoseFrom = $binBatchTable[$key];

                        if ($positionsToChoseFrom.Count -gt 0) {
                            #region uzupełnienie lokalizacji oraz partii do lini
                            $batchLN = 0;

                            while ($pickedQuantity -lt $quantityToBePicked) {
                                #batch
                                $openQuantityToBePicked = $quantityToBePicked - $pickedQuantity;
                
                                for ($i = 0; $i -lt $positionsToChoseFrom.Count; $i++) {
                                    $openPosition = $positionsToChoseFrom[$i];
                                    $openQty = $openPosition.Quantity - $openPosition.UsedQty
                                    if ($openQty -gt 0) {
                                        break;
                                    }
                                }

                                #throw error not enought quantity
                                if ($openQty -eq 0) {
                                    $ms = [string]::Format("Wydanie nie zostało dodane`n`nNa magazynie {0} nie ma wystarczającej ilości dla indeksu: {1}", $WhsCode, $itemCode); 
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                    exit;
                            
                                }

                                if ($openQty -ge $openQuantityToBePicked) {
                                    $qty = $openQuantityToBePicked;

                                }
                                else {
                                    $qty = $openQty;

                                }


                                $countBatchNumbersForLine = $issue.Lines.BatchNumbers.Count;
                        
                                $issue.Lines.BatchNumbers.SetCurrentLine($countBatchNumbersForLine - 1);

                                if ($issue.Lines.BatchNumbers.BatchNumber -ne '') {
                                    $issue.Lines.BatchNumbers.Add()
                                }

                                $issue.Lines.BatchNumbers.BatchNumber = $openPosition.DistNumber;
                                $issue.Lines.BatchNumbers.BaseLineNumber = $issue.Lines.LineNum
                                $issue.Lines.BatchNumbers.Quantity = $qty;

                                $issue.Lines.BinAllocations.BinAbsEntry = $openPosition.BinAbs
                                $issue.Lines.BinAllocations.Quantity = $qty
                                $issue.Lines.BinAllocations.BaseLineNumber = $issue.Lines.LineNum
                                $issue.Lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN
                                $issue.Lines.BinAllocations.Add()

                                $openPosition.UsedQty += $qty;
                                $openQuantityToBePicked -= $qty;
                                $pickedQuantity += $qty;
                                $batchLN++;
                    
                            }      
                        }
                         
                    }    

                    
                    $message = $issue.Add(); 
                    
                    if ($message -lt 0) {
                        $err = $Company.GetLastErrorDescription();
                        $ms = [string]::Format("Wydanie nie zostało dodane`n`nSzczegóły: {0}", $err); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        continue;
                    } 
        
                }
                Catch { 
                    $err = $_.Exception.Message;
                    $ms = [string]::Format("Wydanie nie zostało dodane`n`nSzczegóły: {0}", $err); 
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    continue;
                }
            }

            $ms = [string]::Format("Wyania zostały poprawnie utworzone."); 
            Write-Host -BackgroundColor Green $ms
            Start-Sleep -Seconds 5
        
        } else {
            Start-Sleep -Seconds 5
        }
    } else {
        $msg = [string]::format("Bład połączenia.")
        Write-Host -BackgroundColor Red -ForegroundColor White $msg 
    }
}