
function createDocuments($Company) {
    $lErrCode = 0
    $sErrMsg = ""
    $BPLID =2;


    $SQL_PW_RW_LIST = "SELECT ""Code"" FROM ""@PWRW"" WHERE ""U_STATUS"" = 'C'";
    $SQL_RW_LINES = "SELECT RW.*,wh.""BPLid""  FROM ""@PWRW"" P INNER JOIN ""@PWRWLINIE""  RW ON RW.""U_ParentID"" = P.""Code"" AND RW.""U_Direction"" = 'O'
    inner join OWHS wh on RW.""U_WhsCode""=wh.""WhsCode""
     WHERE P.""U_STATUS"" = 'C' ORDER BY RW.""U_ParentID"", RW.""Code""";
    $SQL_PW_LINES = "SELECT PW.*,wh.""BPLid"" FROM ""@PWRW"" P INNER JOIN ""@PWRWLINIE"" PW ON PW.""U_ParentID"" = P.""Code"" AND PW.""U_Direction"" = 'I' 
     inner join OWHS wh on PW.""U_WhsCode""=wh.""WhsCode""
    WHERE P.""U_STATUS"" = 'C' ORDER BY PW.""U_ParentID"", PW.""Code""";
    $SQL_PW_UPDATE_STATUS = "UPDATE ""@PWRW"" SET ""U_STATUS"" = 'S', ""U_TargetRW"" = '{0}', ""U_TargetPW"" = '{1}'  WHERE ""Code"" = '{2}'";
    
    $SQL_RW_COST_LINES = "SELECT T0.""ItemCode"",T0.""WhsCode"", t1.""TransValue"" * -1 AS ""TransValue""
    FROM IGE1 t0 INNER JOIN OINM t1 ON t0.""DocEntry"" = t1.""CreatedBy"" AND t1.""TransType"" = 60 AND t1.""DocLineNum"" = t0.""LineNum"" 
    WHERE t0.""DocEntry"" = {0}"

    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
    VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),'{0}','{1}','{2}','{3}',CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'GoodsIssueGoodsReceipt.ps1','F')";
    

    $code = $Company.Connected
    if($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'
        $recordSetTemp = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetPwRwList = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetRwLines = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetPwLines = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetUpdate = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetPwRwList.DoQuery($SQL_PW_RW_LIST);
        $recordSetRwLines.DoQuery($SQL_RW_LINES);
        $recordSetPwLines.DoQuery($SQL_PW_LINES);


        $ppPositionsCount = $recordSetPwRwList.RecordCount
        $msg = [string]::format('Dokumentów do utworzenia: {0}',$ppPositionsCount * 2)
        Write-Host -BackgroundColor Blue $msg
        
        if($ppPositionsCount -gt 0){
        
            #region preparing data
            $dictionaryDocuments =  New-Object 'System.Collections.Generic.Dictionary[string,psobject]';

            while(!$recordSetRwLines.EoF)
            {
                $Code = $recordSetRwLines.Fields.Item('Code').Value;
                $ItemCode = $recordSetRwLines.Fields.Item('U_ItemCode').Value;
                $WhsCode = $recordSetRwLines.Fields.Item('U_WhsCode').Value;
                $DistNumber = $recordSetRwLines.Fields.Item('U_DistNumber').Value;
                $Quantity = $recordSetRwLines.Fields.Item('U_Qty').Value;
                $BinAbs = $recordSetRwLines.Fields.Item('U_BinAbs').Value;
                $ParentId = $recordSetRwLines.Fields.Item('U_ParentID').Value;
                $bplID=$recordSetRwLines.Fields.Item('BPLid').Value;
                $Total = -1;

                if($dictionaryDocuments.ContainsKey($ParentId)){
                    if($dictionaryDocuments[$ParentId].ContainsKey('RW')){
                        $dictionaryRW = $dictionaryDocuments[$ParentId]['RW']
                    } else {
                        $dictionaryRW = New-Object 'System.Collections.Generic.Dictionary[string,psobject]';
                        $dictionaryDocuments[$ParentId].Add('RW',$dictionaryRW);
                    }
                } else {
                    $dictionaryRW = New-Object 'System.Collections.Generic.Dictionary[string,psobject]';
                    $temp = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,psobject]]';
                    $temp.Add('RW',$dictionaryRW);
                    $dictionaryDocuments.Add($ParentId,$temp);
                }


                $key =  [string]$ItemCode + '__' + [string]$WhsCode;
                $BatchBinKey = [string]$DistNumber + '__' + [string]$BinAbs;

                if($dictionaryRW.ContainsKey($key)) {
                    $dictLine = $dictionaryRW[$key];
                    $dictLine.Quantity += $Quantity
                } else {
                    $dictLine = [psobject]@{
                        ItemCode = $ItemCode
                        WhsCode = $WhsCode
                        Quantity = $Quantity
                        ParentId = $ParentId
                        Total = $Total
                        bplID=$bplID
                        BinBatches = New-Object 'System.Collections.Generic.Dictionary[string,psobject]'
                    };

                    $dictionaryRW.Add($key, $dictLine);
                }

                if($dictLine.BinBatches.ContainsKey($BatchBinKey)) {
                    $binBatchObject = $dictLine.BinBatches[$BatchBinKey];
                    $binBatchObject.Quantity += $Quantity
                } else {
                    $binBatchObject = [psobject]@{
                        Code = $code
                        ItemCode = $ItemCode
                        WhsCode = $WhsCode
                        Quantity = $Quantity
                        DistNumber = $DistNumber
                        BinAbs = $BinAbs
                        ParentId = $ParentId
                    
                    };

                    $dictLine.BinBatches.Add($BatchBinKey,$binBatchObject);        
                }

                $recordSetRwLines.MoveNext();
            }


            Write-Host 'Przygotowywanie danych PW'
            while(!$recordSetPwLines.EoF)
            {
                $Code = $recordSetPwLines.Fields.Item('Code').Value;
                $ItemCode = $recordSetPwLines.Fields.Item('U_ItemCode').Value;
                $WhsCode = $recordSetPwLines.Fields.Item('U_WhsCode').Value;
                $DistNumber = $recordSetPwLines.Fields.Item('U_DistNumber').Value;
                $Quantity = $recordSetPwLines.Fields.Item('U_Qty').Value;
                $BinAbs = $recordSetPwLines.Fields.Item('U_BinAbs').Value;
                $ParentId = $recordSetPwLines.Fields.Item('U_ParentID').Value;
                $bplID=$recordSetPwLines.Fields.Item('BPLid').Value;
                $Total = -1;

                if($dictionaryDocuments.ContainsKey($ParentId)){
                    if($dictionaryDocuments[$ParentId].ContainsKey('PW')){
                        $dictionaryPW = $dictionaryDocuments[$ParentId]['PW']
                    } else {
                        $dictionaryPW = New-Object 'System.Collections.Generic.Dictionary[string,psobject]';
                        $dictionaryDocuments[$ParentId].Add('PW',$dictionaryPW);
                    }
                } else {
                    $dictionaryPW = New-Object 'System.Collections.Generic.Dictionary[string,psobject]';
                    $temp = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,psobject]]';
                    $temp.Add('PW',$dictionaryPW);
                    $dictionaryDocuments.Add($ParentId,$temp);
                }


                $key =  [string]$ItemCode + '__' + [string]$WhsCode;
                $BatchBinKey = [string]$DistNumber + '__' + [string]$BinAbs;

                if($dictionaryPW.ContainsKey($key)) {
                    $dictLine = $dictionaryPW[$key];
                    $dictLine.Quantity += $Quantity
                } else {
                    $dictLine = [psobject]@{
                        ItemCode = $ItemCode
                        WhsCode = $WhsCode
                        Quantity = $Quantity
                        ParentId = $ParentId
                        Total = $Total
                        bplID=$bplID
                        BinBatches = New-Object 'System.Collections.Generic.Dictionary[string,psobject]'
                    };

                    $dictionaryPW.Add($key, $dictLine);
                }

                if($dictLine.BinBatches.ContainsKey($BatchBinKey)) {
                    $binBatchObject = $dictLine.BinBatches[$BatchBinKey];
                    $binBatchObject.Quantity += $Quantity
                } else {
                    $binBatchObject = [psobject]@{
                        Code = $code
                        ItemCode = $ItemCode
                        WhsCode = $WhsCode
                        Quantity = $Quantity
                        DistNumber = $DistNumber
                        BinAbs = $BinAbs
                        ParentId = $ParentId
                    };

                    $dictLine.BinBatches.Add($BatchBinKey,$binBatchObject);        
                }

                $recordSetPwLines.MoveNext();
            }
            #endregion

            foreach($code in $dictionaryDocuments.Keys){
                $dictionaryDocument = $dictionaryDocuments[$code];
                $createRw = $false;
                $createPw = $false;
                $targetRW = 0;
                $targetPW = 0;
                if($dictionaryDocument.ContainsKey('RW')) {
                    $createRw = $true;
                }

                if($dictionaryDocument.ContainsKey('PW')) {
                    $createPw = $true
                }

                #region preparing Goods Issue
                if($createRw) {
                    try {
                        $rwRecord = $dictionaryDocument['RW'];
                        $issue = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oInventoryGenExit);
                        $issue.BPL_IDAssignedToInvoice = $rwRecord.Values[0].bplID;;

                        foreach($rwLineKey in $rwRecord.Keys) {
                            $rwLine = $rwRecord[$rwLineKey];
                        
                            $issueLine = $issue.Lines;


                            $WhsCode = $rwLine.WhsCode
                            $itemCode = $rwLine.ItemCode


                            $issueLine.ItemCode = $rwLine.ItemCode
                            $issueLine.Quantity = $rwLine.Quantity
                            $issueLine.WarehouseCode = $rwLine.WhsCode
                            $issueLine.AccountCode = '402-01-08';

                            $quantityToBePicked = $rwLine.Quantity
                            $pickedQuantity = 0;
                            $positionsToChoseFrom = $rwLine.BinBatches

                            if($positionsToChoseFrom.Count -gt 0) {
                                #region uzupełnienie lokalizacji oraz partii do lini
                                $batchLN = 0;

                                while($pickedQuantity -lt $quantityToBePicked) {
                                #batch
                                    $openQuantityToBePicked = $quantityToBePicked - $pickedQuantity;
                
                                    foreach($batchKey in $positionsToChoseFrom.Keys)
                                    {
                                        $openPosition = $positionsToChoseFrom[$batchKey];
                                        $openQty = $openPosition.Quantity
                                        if($openQty -gt 0){
                                            break;
                                        }
                                    }

                                    #throw error not enought quantity
                                    if($openQty -eq 0){
                                        $ms = [string]::Format("Wydanie nie zostało dodane`n`nNa magazynie {0} nie ma wystarczającej ilości dla indeksu: {1}`nCode: {2}",$WhsCode, $itemCode,$code); 
                                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                        if($Company.InTransaction){
                                            $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                                        }

                                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                                        $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenExit,'DocEntry','',$ms);
                                        $recordSetTemp.DoQuery($logQuery);
                                        continue;
                            
                                    }

                                    if($openQty -ge $openQuantityToBePicked)
                                    {
                                        $qty = $openQuantityToBePicked;

                                    } else {
                                        $qty = $openQty;

                                    }


                                    $issue.Lines.BatchNumbers.BatchNumber = $openPosition.DistNumber;
                                    $issue.Lines.BatchNumbers.BaseLineNumber = $issue.Lines.LineNum
                                    $issue.Lines.BatchNumbers.Quantity = $qty;
                                    $issue.Lines.BatchNumbers.Add()

                                    $issue.Lines.BinAllocations.BinAbsEntry = $openPosition.BinAbs
                                    $issue.Lines.BinAllocations.Quantity = $qty
                                    $issue.Lines.BinAllocations.BaseLineNumber = $issue.Lines.LineNum
                                    $issue.Lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN
                                    $issue.Lines.BinAllocations.Add()




                                    $openPosition.Quantity -= $qty;
                                    $openQuantityToBePicked -= $qty;
                                    $pickedQuantity += $qty;
                                    $batchLN++;
                   
                                }      
                            }

                        }
                    } Catch {
                        $err=$_.Exception.Message;
                        $ms = [string]::Format("Błąd podczas przygotowywania dokumentu wydania`n`nSzczegóły: {0}`nCode: {1}",$err,$code); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        if($Company.InTransaction){
                            $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                        }
                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                        $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenExit,'DocEntry','',$ms);
                        $recordSetTemp.DoQuery($logQuery);
                        continue;
                    }

                }
                #endregion

                #region preparing Goods Receipt
                if($createPw) {
                    try {
                        $pwRecord = $dictionaryDocument['PW'];
                        $receipt = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oInventoryGenEntry);
                        $receipt.BPL_IDAssignedToInvoice = $pwRecord.Values[0].bplID;
                        
                        foreach($pwLineKey in $pwRecord.Keys) {
                            $pwLine = $pwRecord[$pwLineKey];
                        
                            $receiptLine = $receipt.Lines;


                            $WhsCode = $pwLine.WhsCode
                            $itemCode = $pwLine.ItemCode

                            $receiptLine.ItemCode = $pwLine.ItemCode
                            $receiptLine.Quantity = $pwLine.Quantity
                            $receiptLine.WarehouseCode = $pwLine.WhsCode
                            $receiptLine.AccountCode = '402-01-08'
                            
                            #if $pwLine.Total -1 cost will be setup from goods issue just before adding receipt
                            if($pwLine.Total -gt 0){
                                $receiptLine.LineTotal = $pwLine.Total
                            }

                            $quantityToBePicked = $pwLine.Quantity
                            $pickedQuantity = 0;
                            $positionsToChoseFrom = $pwLine.BinBatches

                            if($positionsToChoseFrom.Count -gt 0) {
                                #region uzupełnienie lokalizacji oraz partii do lini
                                $batchLN = 0;

                                while($pickedQuantity -lt $quantityToBePicked) {
                                #batch
                                    $openQuantityToBePicked = $quantityToBePicked - $pickedQuantity;
                
                                    foreach($batchKey in $positionsToChoseFrom.Keys)
                                    {
                                        $openPosition = $positionsToChoseFrom[$batchKey];
                                        $openQty = $openPosition.Quantity
                                        if($openQty -gt 0){
                                            break;
                                        }
                                    }

                                    #throw error not enought quantity
                                    if($openQty -eq 0){
                                        $ms = [string]::Format("Przyjęcie nie zostało dodane`n`nNa magazynie {0} nie ma wystarczającej ilości dla indeksu: {1},`nCode: {2}",$WhsCode, $itemCode,$code); 
                                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                        if($Company.InTransaction){
                                            $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                                        }
                                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                                        $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenEntry,'DocEntry','',$ms);
                                        $recordSetTemp.DoQuery($logQuery);
                                        continue;
                            
                                    }

                                    if($openQty -ge $openQuantityToBePicked)
                                    {
                                        $qty = $openQuantityToBePicked;

                                    } else {
                                        $qty = $openQty;

                                    }


                                    $receipt.Lines.BatchNumbers.BatchNumber = $openPosition.DistNumber;
                                    $receipt.Lines.BatchNumbers.BaseLineNumber = $receipt.Lines.LineNum
                                    $receipt.Lines.BatchNumbers.Quantity = $qty;
                                    $receipt.Lines.BatchNumbers.Add()

                                    $receipt.Lines.BinAllocations.BinAbsEntry = $openPosition.BinAbs
                                    $receipt.Lines.BinAllocations.Quantity = $qty
                                    $receipt.Lines.BinAllocations.BaseLineNumber = $receipt.Lines.LineNum
                                    $receipt.Lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN
                                    $receipt.Lines.BinAllocations.Add()




                                    $openPosition.Quantity -= $qty;
                                    $openQuantityToBePicked -= $qty;
                                    $pickedQuantity += $qty;
                                    $batchLN++;
                   
                                }      
                            }

                        }

                        

                    } Catch {
                        $err=$_.Exception.Message;
                        $ms = [string]::Format("Błąd podczas przygotowywania dokumentu przyjęcia`n`nSzczegóły: {0}`nCode: {1}",$err,$code); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        if($Company.InTransaction){
                            $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                        }
                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                        $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenEntry,'DocEntry','',$ms);
                        $recordSetTemp.DoQuery($logQuery);
                        continue;
                    }

                

                
                }
                #endregion

                $Company.StartTransaction();
                if($createRw)
                {
                    try {
                        $message = $issue.Add();
                
                        if($message -lt 0)
                        {
                            $err= $Company.GetLastErrorDescription();
                            $ms = [string]::Format("Wydanie nie zostało dodane`n`nSzczegóły: {0}`nCode: {1}",$err,$code); 
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            if($Company.InTransaction){
                                $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                            }
                            # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                            $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenExit,'DocEntry','',$ms);
                            $recordSetTemp.DoQuery($logQuery);
                            continue;
                        }
                        else {
                                $ms = [string]::Format("Wydanie zostało poprawnie utworzone."); 
                                Write-Host -BackgroundColor Green $ms
                                $targetRW = $Company.GetNewObjectKey();

                                if($createPw -and ($pwRecord.Values[0].Total -eq -1))
                                {
                                    $costQuery = [string]::Format($SQL_RW_COST_LINES,$targetRW);
                                    $recordSetTemp.DoQuery($costQuery);
                                    
                                    
                                    while(!$recordSetTemp.EoF)
                                    {
                                        $ItemCode = $recordSetTemp.Fields.Item('ItemCode').Value;
                                        $WhsCode = $recordSetTemp.Fields.Item('WhsCode').Value;
                                        $Total = $recordSetTemp.Fields.Item('TransValue').Value;

                                        $key =  [string]$ItemCode + '__' + [string]$WhsCode;
                                        $rwRecord[$key].Total = $Total
                                        $recordSetTemp.MoveNext();
                                    }
                                }

                        }
                    } Catch {
                        $err=$_.Exception.Message;
                        $ms = [string]::Format("Dokument wydania nie został utworzony`n`nSzczegóły: {0}`nCode: {1}",$err,$code); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        if($Company.InTransaction){
                            $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                        }
                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                        $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenExit,'DocEntry','',$ms);
                        $recordSetTemp.DoQuery($logQuery);
                        continue;
                    } 

                }

                if($createPw)
                {
                    try {
                        #calculate totals
                        if($createRw -and ($pwRecord.Values[0].Total -eq -1)) {
                        
                            $itemsCount = $receipt.Lines.Count
                        
                            for($xi = 0; $xi -lt $itemsCount; $xi++){
                                $receipt.Lines.SetCurrentLine($xi);
                                $receiptLine = $receipt.Lines
                                $key =  [string]$receiptLine.ItemCode + '__' + [string]$receiptLine.WarehouseCode
                                if($rwRecord.ContainsKey($key)){
                                    $total = $rwRecord[$key].Total    
                                    $receiptLine.LineTotal = $total;
                                }
                            }
                        }
                        $message = $receipt.Add();
                        if($message -lt 0)
                        {
                            $err= $Company.GetLastErrorDescription();
                            $ms = [string]::Format("Przyjęcie nie zostało dodane`n`nSzczegóły: {0}`nCode: {1}",$err,$code); 
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            if($Company.InTransaction){
                                $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                            }
                            # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                            $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenEntry,'DocEntry','',$ms);
                            $recordSetTemp.DoQuery($logQuery);
                            continue;
                        }
                        else
                        {
                            $ms = [string]::Format("Przyjęcie zostało poprawnie utworzone."); 
                            Write-Host -BackgroundColor Green $ms
                            $targetPW = $Company.GetNewObjectKey();
                        }
                    } Catch {
                        $err=$_.Exception.Message;
                        $ms = [string]::Format("Dokument przyjęcia nie został dodany`n`nSzczegóły: {0}`nCode: {1}",$err,$code); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        if($Company.InTransaction){
                            $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntReject)
                        }
                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                        $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oInventoryGenEntry,'DocEntry','',$ms);
                        $recordSetTemp.DoQuery($logQuery);
                        continue;
                    } 
                }


                if($Company.InTransaction){
                    $Company.EndTransaction([SAPbobsCOM.BoTransactionTypeEnum]::botrntComplete)
                }
                $updateQuery = [string]::Format($SQL_PW_UPDATE_STATUS,$targetRW,$targetPW,$code);
                $recordSetUpdate.DoQuery($updateQuery);
            }
            Start-Sleep -Seconds 20
        } else {
             Start-Sleep -Seconds 20;
        }
    }
    else
    {
        $msg = [string]::format("Bład połączenia.")
        Write-Host -BackgroundColor Red -ForegroundColor White $msg
    }
}