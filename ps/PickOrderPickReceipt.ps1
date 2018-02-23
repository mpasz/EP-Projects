function failureUpdatePickOrder( $docEntry ) {
    try {
        $SQL_UPDATE_FAILURE = "UPDATE ""@CT_PF_OPRE"" SET U_STATUS_PS='F' WHERE ""DocEntry"" = @DocEntry ;";
        $queryManagerUpdate = New-Object CompuTec.Core.DI.Database.QueryManager
		$queryManagerUpdate.CommandText = $SQL_UPDATE_FAILURE


        if($docEntry -gt 0) {
            $queryManagerUpdate.ClearParameters();
            $queryManagerUpdate.AddParameter("DocEntry", $docEntry);
            $dummy = $queryManagerUpdate.Execute($pfcCompany.Token);
        }
    } catch { 
        continue; 
    }
}
function logError($pfcCompany,$Object,$KeyName,$KeyValue,$Remarks){
    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
            VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),@Object,@Key_Name,@Key_Value,@Remarks,CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'PickOrderPickReceipt.ps1','F')";
    try {
        $queryManagerLog = New-Object CompuTec.Core.DI.Database.QueryManager
        $queryManagerLog.CommandText = $SQL_INSERT_LOG;
        $queryManagerLog.AddParameter("Object", $Object);
        $queryManagerLog.AddParameter("Key_Name", $KeyName);
        $queryManagerLog.AddParameter("Key_Value", $KeyValue);
        $queryManagerLog.AddParameter("Remarks", $Remarks);
        $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
    } catch {
        continue;
    }
}
function CreateDocuments($pfcCompany, $WATCHDOG_FILENAME ) {
    $LogFileName = 'C:\Temp\PickOrderPicReceiptLog.txt';
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Wywo�anie funkcji: '  >> $LogFileName
    . $PSScriptRoot\ProcessOrderLine.ps1

    $SQLQUERY_PICK_Receipt_LIST = "

select  t0.""DocEntry"", t4.""U_LineNum"", sum(t0.""U_Quantity"") ""Qty""
from
""@CT_PF_PRE2""  t0 
--inner join ""@CT_PF_PRE4"" t1 on t0.""DocEntry""=t1.""DocEntry"" and t1.""U_SnAndBnLine""=t0.""U_LineNum""
inner join ""@CT_PF_PRE3""  t3 on t0.""DocEntry""=t3.""DocEntry"" and t0.""U_LineNum""=t3.""U_PickItemLineNo""
inner join ""@CT_PF_PRE1""  t4 on t0.""DocEntry""=t4.""DocEntry"" and t4.""U_LineNum""=t3.""U_ReqItemLineNo""
inner join ""@CT_PF_OPRE"" t5 on t0.""DocEntry""=t5.""DocEntry"" 

inner join ""@CT_PF_OMOR"" t7 on t4.""U_BaseEntry""=t7.""DocEntry""
where --t0.""DocEntry""=5002 and 
IFNULL(t0.""U_Receipted"",'N')<>'Y' AND IFNULL(t5.U_STATUS_PS,'') <> 'F'  --and ""U_Status"" <>'C'
group by t0.""DocEntry"", t4.""U_LineNum"";"

    $SQLQUERYORDER_LIST = "
 call GetIssueList(@DE,@LN);
 "
#check if empty Pick Order exists
$SQLQUERY_PICK_ORDER="select t1.""DocEntry"" from ""@CT_PF_PRE1"" t0 
 inner join ""@CT_PF_POR1"" t1 on t0.""U_BaseEntry"" =t1.""U_BaseEntry""
 where t0.""DocEntry""=@DE and t0.""U_LineNum""=@LN and t1.""U_IssuedQty""=0 and t1.""U_PickedQty""=0;
 ";
    $ReceiptPriceQuery =" call CT_GetReceiptPrice( @DE,@LN,@QTY);"
   
    #Database connection

    New-Item $WATCHDOG_FILENAME -type file -Force
    $code = $pfcCompany.IsConnected
    if ($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'
        $LogDateTime = Get-Date
        [string]$LogDateTime + ' Przed zapytaniami: '  >> $LogFileName
        #Query
        $queryManager = New-Object CompuTec.Core.DI.Database.QueryManager
		$queryManager.CommandText = $SQLQUERY_PICK_Receipt_LIST
		$rs = $queryManager.Execute($pfcCompany.Token);
        $ppPositionsCount = $rs.RecordCount
        if ($ppPositionsCount -gt 0) {
            $msg = [string]::format('positions to add: {0}', $ppPositionsCount)
            Write-Host -BackgroundColor Blue $msg

            $prevDocEntry = -1;
            $prevLineNum = -1;
            #[docEntry][U_LineNum]
            $MainList = New-Object 'System.Collections.Generic.List[psobject]'
            #[docEntry][U_LineNum][object-line]
           
            Write-Host 'Przygotowywanie danych o pozycjach'
            while (!$rs.EoF) {
                $docEntry = $rs.Fields.Item('DocEntry').Value;
                $lineNum = $rs.Fields.Item('U_LineNum').Value;
    
                $MainList.Add([psobject]@{
                        DocEntry = $docEntry
                        LineNum  = $lineNum
                    });
                 
                $rs.MoveNext();
            }
            foreach ($info in $MainList) {
                $dodano = $false
                New-Item $WATCHDOG_FILENAME -type file -Force

                $queryManager2 = New-Object CompuTec.Core.DI.Database.QueryManager
				$queryManager2.CommandText = $SQLQUERYORDER_LIST;
                $queryManager2.AddParameter("DE", $info.DocEntry)
                $queryManager2.AddParameter("LN", $info.LineNum)
                $list = New-Object 'System.Collections.Generic.List[psobject]'
                $rs2 = $queryManager2.Execute($pfcCompany.Token);
                $LineQty = 0
                $stuCodesLine = '';
                $ItemCode = ''
                $MorDocEntry = 0;
                $whs = ''
                if ($rs2.RecordCount -eq 0) {
                    failureUpdatePickOrder($info.DocEntry)  
                    $err = "Brak pozycj do wydania do zlecenia produkcyjnego.";
                    $ms = [string]::Format("Przyj�cie oraz wydanie nie zosta�o dodane. DocEntry: {0}`n`nSzczeg�y: {1}", $info.DocEntry, $err);

                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms

                    $Object = 'CT_PF_PickReceipt';
                    $KeyName = 'DocEntry';
                    $KeyValue = $info.DocEntry;
                    $Remarks = $ms;

                    if ($pfcCompany.InTransaction) {
                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                    }
                    logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                    continue;
                }
                $rs2.MoveFirst();
                while (!$rs2.EoF) { 

                    $MorDocEntry = $rs2.Fields.Item('MorDocEntry').Value;
                    $fromDistNumber = $rs2.Fields.Item('Dist Number').Value;
                    $fromBinAbs = $rs2.Fields.Item('BinAbs').Value;
                    $ItemCode = $rs2.Fields.Item('ItemCode').Value;
                    $whs = $rs2.Fields.Item('WhsCode').Value;
                    $qty = $rs2.Fields.Item('Qty').Value;
                    $stuCodes = $rs2.Fields.Item('Units').Value;
                    $LineQty = $LineQty + $qty
                    $stuCodesLine += ',' + [string]$stuCodes + ';' + $qty.ToString();
                    $list.Add( [psobject]@{
                            Quantity       = $qty
                            UsedQuantity   = 0
                            FromBinAbs     = $fromBinAbs
                            FromDistNumber = $fromDistNumber
                            ToWhsCode      = $whs
                        });
                    $rs2.MoveNext();
                }
                $akcja = [psobject]@{
                    ItemCode         = $ItemCode
                    LineQty          = $LineQty
                    MorDocEntry      = $MorDocEntry
                    stuCodesLine     = $stuCodesLine
                    Rows             = $list
                    PickReceitpEntry = $info.DocEntry
                    WhsCode          = $whs;
                };
                try {


                    try {
                        $LogDateTime = Get-Date
                        [string]$LogDateTime + ' Rozpoczęcie transakcji: '  >> $LogFileName
                       
                        #$ST= $pfcCompany.CreateSapObject([SAPbobsCOM.BoObjectTypes]::oInventoryTransferRequest)
                        # write-host $key
                       # $pickOrderAction = $pfcCompany.CreatePFAction([CompuTec.ProcessForce.API.Core.ActionType]::CreatePickOrderForProductionIssue);
                        $pickReceiptAction = $pfcCompany.CreatePFAction([CompuTec.ProcessForce.API.Core.ActionType]::CreateGoodsReceiptFromPickReceiptBasedOnProductionReceipt);
                    


                $createPickOrderQuery=New-Object CompuTec.Core.DI.Database.QueryManager
                $createPickOrderQuery.CommandText=$SQLQUERY_PICK_ORDER;
                $createPickOrderQuery.AddParameter("DE",$info.DocEntry)
                $createPickOrderQuery.AddParameter("LN",$info.LineNum)
                $docentryPickOrder = 0
                $rs7=$createPickOrderQuery.Execute($pfcCompany.Token);
                if ($rs7.RecordCount -eq 0)
                {


                    $pickOrderAction = $pfcCompany.CreatePFAction([CompuTec.ProcessForce.API.Core.ActionType]::CreatePickOrderForProductionIssue);
                    $pickOrderAction.AddMORDocEntry($akcja.MorDocEntry);
                    Write-Host 'Utworzenie dokumentu wydania';
                    $dummy = $pickOrderAction.DoAction([ref] $docentryPickOrder); 
                }else
                {
                    $docentryPickOrder=$rs7.Fields.Item(0).Value;
                }



                         
                        $pickReceiptAction.PickReceiptID = $akcja.PickReceitpEntry;
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White ' MO' $akcja.MorDocEntry "Pick" $akcja.PickReceitpEntry
                        $tempDictionary = New-Object 'System.Collections.Generic.Dictionary[int,System.Collections.Generic.List[int]]'
                        #                   $tempDictionary.Add($action, $dictionary[$key]);
                   
                       
                        Write-Host 'Utworzenie dokumentu wydania';
                         
                     
                        $pickOrder = $pfcCompany.CreatePFObject([CompuTec.ProcessForce.API.Core.ObjectTypes]::PickOrder)
                    
                    
                    
                        $docentryPickReceipt = 0;

                    
                        $retval = $pickOrder.GetByKey($docentryPickOrder);
                        if ($retVal -ne 0) {    
                            $err = $pfcCompany.GetLastErrorDescription()
                            $ms = [string]::Format("Wydanie nie zostało pobrane.DocEntry: {0}`n`nSzczegóły: {1}`nSTUCode: {2}", $docentryPickOrder, $err, $dictionaryLine.StuCodes);

                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms

                            $Object = 'CT_PF_PickOrder';
                            $KeyName = 'MORDocEntry';
                            $KeyValue = $key;
                            $Remarks = $ms;

                            if ($pfcCompany.InTransaction) {
                                $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                            }
                            logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                            failureUpdatePickOrder $info.DocEntry;
                            continue;
                        }
                    }
                    Catch {
                        $err = $_.Exception.Message;
                        $ms = [string]::Format("Wydanie nie zostało utworzone.`n`nSzczegóły: {0}`nSTUCode: {1}", $err, $dictionaryLine.StuCodes);
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        $Object = 'CT_PF_PickOrder';
                        $KeyName = 'MORDocEntry';
                        $KeyValue = $key;
                        $Remarks = $ms;

                        if ($pfcCompany.InTransaction) {
                            $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                        }
                        logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                        failureUpdatePickOrder $info.DocEntry;

                        continue;
                    }
        
                    if ($docentryPickOrder -gt 0) {
                
                        $binAllocationList = New-Object 'System.Collections.Generic.List[psobject]'

                        $count = $pickOrder.RequiredItems.Count;
                        $msg = [string]::format('Uzupelnienie dokumentu wydania. Pozycji do uzupelnienia:{0}', $count);
                        Write-Host $msg
                        for ($j = 0; $j -lt $pickOrder.RequiredItems.Count; $j++) {
                            $pickOrder.RequiredItems.SetCurrentLine($j);
                        
                        
                            if ( $pickOrder.RequiredItems.U_ItemCode -ne $akcja.ItemCode ) {
                                continue;
                            }



                            $msg = [string]::format('{0}/{1}', $j + 1, $count)
                            Write-Host $msg
                            #region uzupełnienie pozycji

                            $lineBaseEntry = $pickOrder.RequiredItems.U_BaseEntry;
                            $lineBaseLineNum = $pickOrder.RequiredItems.U_BaseLineNo;
                       
                            #$StockTransferRequest.FromWarehouse= $dictionaryLine.FromWhs
                            # $StockTransferRequest.ToWarehouse= $dictionaryLine.MMTO
                            $binBatchTable = $akcja.Rows;
                            $quantityToBePicked = $akcja.LineQty
                            $pickedQuantity = 0;
                            $itemCode = $pickOrder.RequiredItems.U_ItemCode;
                            $WhsCode = $akcja.WhsCode

                            $pickOrder.RequiredItems.U_PickedQty = $quantityToBePicked;
                            $pickOrder.RequiredItems.U_SrcWhsCode = $WhsCode;

                            $reqitemsLN = $pickOrder.RequiredItems.U_LineNum;
                            $positionsToChoseFrom = $binBatchTable;

                            if ($positionsToChoseFrom.Count -gt 0) {
                                #region uzupełnienie lokalizacji oraz partii do lini
                                while ($pickedQuantity -lt $quantityToBePicked) {
                                    #batch
                                    $openQuantityToBePicked = $quantityToBePicked - $pickedQuantity;
                        

                                    $x = $pickOrder.PickedItems.SetCurrentLine($pickOrder.PickedItems.Count - 1);
                                    $pickOrder.PickedItems.U_ItemCode = $itemCode;

                                    foreach ($openPosition in $positionsToChoseFrom) {
                                        if ($openPosition.Quantity -gt 0) {
                                            break;
                                        }
                                    }

                                    #throw error not enought quantity
                                    if ($openPosition.Quantity -eq 0) {
                                        $ms = [string]::Format("Wydanie {0} nie zostało zaktualizowane`n`nNa magazynie {1} nie ma wystarczającej ilości dla indeksu: {2}`nSTUCode: {3} ", $pickOrder.DocNum, $WhsCode, $itemCode, $akcja.stuCodesLine); 
                                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                        $Object = 'CT_PF_PickOrder';
                                        $KeyName = 'DocEntry';
                                        $KeyValue = $pickOrder.DocEntry;
                                        $Remarks = $ms;

                                
                                        if ($pfcCompany.InTransaction) {
                                            $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                        }
                                        logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                                        failureUpdatePickOrder $info.DocEntry;
                                        continue;
                            
                                    }

                                    if ($openPosition.Quantity -ge $openQuantityToBePicked) {
                                        $qty = $openQuantityToBePicked;

                                    }
                                    else {
                                        $qty = $openPosition.Quantity;

                                    }

                                    $pickOrder.PickedItems.U_BnDistNumber = $openPosition.FromDistNumber;
                                    $pickOrder.PickedItems.U_Quantity = $qty;
                                    $openPosition.Quantity -= $qty;
                                    $openQuantityToBePicked -= $qty;
                                    $pickedQuantity += $qty;
                                    $pickItemsLN = $pickOrder.PickedItems.U_LineNum;

                                    $binAllocationObject = [psobject]@{
                                        BinAbs      = $openPosition.FromBinAbs;
                                        Quantity    = $qty;
                                        SnAndBnLine = $pickItemsLN;
                                    };

                                    $x = $binAllocationList.Add($binAllocationObject);

                                    $x = $pickOrder.PickedItems.Add()

                                    #Specify relation Beetween picked and Required Line
                                    $pickOrder.Relations.SetCurrentLine($pickOrder.Relations.Count - 1);
                                    $pickOrder.Relations.U_ReqItemLineNo = $reqitemsLN;
                                    $pickOrder.Relations.U_PickItemLineNo = $pickItemsLN;
                                    $x = $pickOrder.Relations.Add(); 
                           
                                }
                
                            }
                            else {
                                $pickOrder.PickedItems.SetCurrentLine($pickOrder.PickedItems.Count - 1);
                                $pickOrder.PickedItems.U_ItemCode = $itemCode;
                                $pickOrder.PickedItems.U_Quantity = $quantityToBePicked;
                                $pickItemsLN = $pickOrder.PickedItems.U_LineNum;
                                $x = $pickOrder.PickedItems.Add();

                                #Specify relation Beetween picked and Required Line
                                $pickOrder.Relations.SetCurrentLine($pickOrder.Relations.Count - 1);
                                $pickOrder.Relations.U_ReqItemLineNo = $reqitemsLN;
                                $pickOrder.Relations.U_PickItemLineNo = $pickItemsLN;
                                $x = $pickOrder.Relations.Add();
                            }
           
                            #endregion
                            #endregion
                        }    

                        for ($i = 0; $i -lt $binAllocationList.Count; $i++) {
                            $binAllocationObject = $binAllocationList[$i];
                            $pickOrder.BinAllocations.U_BinAbsEntry = $binAllocationObject.BinAbs;
                            $pickOrder.BinAllocations.U_Quantity = $binAllocationObject.Quantity;
                            $pickOrder.BinAllocations.U_SnAndBnLine = $binAllocationObject.SnAndBnLine;
                            $x = $pickOrder.BinAllocations.Add()

                        }
                        $LogDateTime = Get-Date
                        [string]$LogDateTime + ' Dokument wydania dodany: '  >> $LogFileName
                        try { 

                            Write-Host 'Utworzenie dokumentu przyjęcia';
                            $pfcCompany.StartTransaction();
                            $LogDateTime = Get-Date
                            [string]$LogDateTime + ' rozpoczynamy transakcje SAP: '  >> $LogFileName
                            $message = $pickOrder.Update();
                            if ($message -lt 0) {
                                $err = $pfcCompany.GetLastErrorDescription()
                                $ms = [string]::Format("Wydanie {0} nie zostało zaktualizowane`n`nSzczegóły: {1}`nSTUCode: {2}", $pickOrder.DocNum, $err, $akcja.stuCodesLine); 
                                $Object = 'CT_PF_PickOrder';
                                $KeyName = 'DocEntry';
                                $KeyValue = $pickOrder.DocEntry;
                                $Remarks = $ms;

                                #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                                Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                if ($pfcCompany.InTransaction) {
                                    $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                }
                                logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                                failureUpdatePickOrder $info.DocEntry;
                                continue;
                            } 
                            $ref= $pickOrder.GetCreatedDocumentReferences()
                            $IssueEntry=  $ref[0].DocEntry
                        }
                        Catch {
                            $err = $_.Exception.Message;
                            $ms = [string]::Format("Wydanie {0} nie zostało zaktualizowane`n`nSzczegóły: {1}`nSTUCode: {2}", $pickOrder.DocNum, $err, $akcja.stuCodesLine); 
                            $Object = 'CT_PF_PickOrder';
                            $KeyName = 'DocEntry';
                            $KeyValue = $pickOrder.DocEntry;
                            $Remarks = $ms;

                            #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            if ($pfcCompany.InTransaction) {
                                $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                            }
                            logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                            failureUpdatePickOrder $info.DocEntry;
                            continue; 
                        }
            
                        $ms = [string]::Format("Wydanie zostało poprawnie utworzone. Numer dokumentu: {0}", $pickOrder.DocNum); 
                        Write-Host -BackgroundColor Green $ms

                    }

                    else {
                        if ($pfcCompany.InTransaction) {
                            $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                        }

                        $Object = 'CT_PF_PickOrder';
                        $KeyName = 'DocEntry';
                        $KeyValue = -555;
                           
                        $ms = [string]::Format("Wydanie nie zostalo wykonane - nie wiadomo dlaczego Zlexcenie prod klucz- {0} nie zostalo zaktualizowane`n`nSzczegoly: {1}`nSTUCode: {2}", $akcja.MorDocEntry , $err, $akcja.stuCodesLine); 
                        $Remarks = $ms;
                        logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                        failureUpdatePickOrder $info.DocEntry
                        continue;
                    }

                    try { 

                        $b = New-Object CompuTec.Core.DI.Database.QueryManager
                        $b.CommandText = "update ""@CT_PF_OPRE"" set ""U_Status"" ='S' where ""DocEntry""=@DE";
                        $b.AddParameter("DE", $akcja.PickReceitpEntry);
         
                        $recb = $b.Execute($pfcCompany.Token);
                        $recb.Dispose();
                        $blok = New-Object CompuTec.Core.DI.Database.QueryManager
                        $blok.CommandText = "select ""U_PickedQty"" from  ""@CT_PF_PRE1"" where ""DocEntry""=@DE and ""U_LineNum""=@LN";
                        $blok.AddParameter("DE", $akcja.PickReceitpEntry);
                        $blok.AddParameter("LN", $info.LineNum);
                        $blocrec = $blok.Execute($pfcCompany.Token);
                        if ( $LineQty -ne $blocrec.Fields.Item("U_PickedQty").Value) {
                            
                            $err = 'blokujemy przyjecie  ilosci nie są zgodne'
                            $ms = [string]::Format("Przyjęcie {0} nie zostało zaktualizowane`n`nSzczegóły: {1}`nSTUCode: {2}", $tempDictionary2, $err, $akcja.stuCodesLine)
                            $Object = 'CT_PF_Receipt';
                            $KeyName = 'DocEntry';
                            $KeyValue = $akcja.PickReceitpEntry;
                            $Remarks = $ms;

                            #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            if ($pfcCompany.InTransaction) {
                                $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                            }
                    
                            logError $pfcCompany $Object $KeyName $KeyValue $Remarks 
                            failureUpdatePickOrder $info.DocEntry
                            continue;
                        }
                        $goodsReceiptEntry = 0         
                        
                                                ## Update Price and Partia Klienta
                        $e = New-Object CompuTec.Core.DI.Database.QueryManager
                        $e.CommandText ="Call CT_GetReceiptPrice(@DE ,@IDE)";
                        $e.AddParameter("DE", $akcja.PickReceitpEntry);
                        $e.AddParameter("IDE", $IssueEntry);
                        $recb = $e.Execute($pfcCompany.Token);
                        $recb.Dispose();
                        ## Update Price and Partia Klienta             
                        $cus = $pickReceiptAction.DoAction([ref] $goodsReceiptEntry)
                        if ($cus -ne $true) {
                        
                            $err = $pfcCompany.GetLastErrorDescription()
                            $ms = [string]::Format("Prtzyjecie {0} nie zostało zaktualizowane`n`nSzczegóły: {1}`nSTUCode: {2}", $tempDictionary2, $err, $akcja.stuCodesLine)
                            $Object = 'CT_PF_Receipt';
                            $KeyName = 'DocEntry';
                            $KeyValue = $akcja.PickReceitpEntry;
                            $Remarks = $ms;

                            #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            if ($pfcCompany.InTransaction) {
                                $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                            }
                            logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                            failureUpdatePickOrder $info.DocEntry
                            continue;
                        }
                        else {
                            $dodano = $true
                        }
 
                    }
                    Catch {
                        $err = $_.Exception.Message;
                        $ms = [string]::Format("Prtzyjecie {0} nie zostało zaktualizowane`n`nSzczegóły: {1}`nSTUCode: {2}", $tempDictionary2, $err, $akcja.stuCodesLine); 
                        $Object = 'CT_PF_PickOrder';
                        $KeyName = 'DocEntry';
                        $KeyValue = $akcja.PickReceitpEntry;
                        $Remarks = $ms;

                        #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        if ($pfcCompany.InTransaction) {
                            $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                        }
                        logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                        failureUpdatePickOrder $info.DocEntry
                        continue;
                    }
                    if ($pfcCompany.InTransaction) {
                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Commit);
                        $ms = [string]::Format("Przyjęcie zostało poprawnie utworzone. Numer dokumentu: {0}", $akcja.PickReceitpEntry); 
                        Write-Host -BackgroundColor Green $ms
                        $lst = New-Object System.Collections.ArrayList;
                        $SuCode = $akcja.stuCodesLine;
                        $lst.AddRange($SuCode.ToString().Split(','));

                        if ($dodano -eq $true) {
                            CloseSUAfterReceipt -pfcCompany $pfcCompany -SUs $lst;
                        }
                    }
                
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Przycjęcie dodane: '  >> $LogFileName
                }
                Catch {
                    $err = $_.Exception.Message;
                    $ms = [string]::Format("Błąd w skrypcie: {1}`nSTUCode: {2}", $tempDictionary2, $err, $akcja.stuCodesLine); 
                    $Object = 'CT_PF_PickOrder';
                    $KeyName = 'DocEntry';
                    $KeyValue = $akcja.PickReceitpEntry;
                    $Remarks = $ms;

                    #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    if ($pfcCompany.InTransaction) {
                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                    }
                    logError $pfcCompany $Object $KeyName $KeyValue $Remarks
                    failureUpdatePickOrder $info.DocEntry
                    continue;
                }
                 
            }
            Start-Sleep -Seconds 5
        }
        else {
            $msg = [string]::format('Brak pozycji do wydania')
            Write-Host -BackgroundColor Blue $msg
            Start-Sleep -Seconds 5
        }
    }
    else {
        $msg = [string]::format("Bład połączenia.")
        $x = [Microsoft.VisualBasic.Interaction]::MsgBox($msg, [Microsoft.VisualBasic.MsgBoxStyle]::Critical, "Bład połączenia do SAP'a.");
    }
}





