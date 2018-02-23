clear
# użycie biblioteki SAPbobsCOM.dll
add-type -Path "C:\Computec\Powershell\Interop.SAPbobsCOM.dll"
add-type -Path "C:\Computec\Powershell\Interop.SAPbouiCOM.dll"
$Company = new-Object -ComObject SAPbobsCOM.Company
$Company.Server = "172.16.0.54:30015"
$Company.DbUserName = "SYSTEM"
$Company.DbPassword = "Ep*4321#"
$Company.CompanyDB = "TEST_PROD_NS_080517"
$Company.LicenseServer = "172.16.0.53:40000"
$Company.UserName = "rafald"
$Company.Password = "1234"
$Company.DbServerType = [SAPbobsCOM.BoDataServerTypes]::dst_HANADB
$lErrCode = 0
$sErrMsg = ""

$SQL_PICK_LIST = "SELECT
 ""DocEntry""
FROM ""@CT_ZW_NAG""
WHERE ""DocEntry"" NOT IN (SELECT IFNULL(""U_ZW"",0) FROM OPKL) AND ""DocEntry"" > 12 AND IFNULL(""U_PickRelease"",'N') = 'T'  ORDER BY ""DocEntry""" ;

$SQLQUERY_PICK_ORDER_LIST = "SELECT DISTINCT
T0.""U_DocEntryZS"" AS ""DocEntry"", T0.""U_ItemCode"" AS ""ItemCode"", T0.""U_LineNumZS"" AS ""LineNum"", T2.""WhsCode"", T0.""U_QtySum"" AS ""Quantity"", 
T2.""RowNum"", T1.""DocEntry"" AS ""Ref"", IFNULL(T3.""USER_CODE"",'brak') AS ""USERID""
FROM ""@CT_ZW_POZ"" T0
 INNER JOIN ""@CT_ZW_NAG"" t1 on t0.""DocEntry""=t1.""DocEntry""
 INNER JOIN 
 	(SELECT T2.""DocEntry"", T2.""LineNum"", T2.""WhsCode"", ROW_NUMBER()OVER(PARTITION BY ""DocEntry"" ORDER BY T2.""DocEntry"", T2.""LineNum"")-1 AS ""RowNum""  
 	 FROM RDR1 T2) 
 	 AS T2 ON T0.""U_DocEntryZS"" = T2.""DocEntry"" AND T0.""U_LineNumZS"" = T2.""LineNum""
 LEFT OUTER JOIN OUSR T3 ON T1.""U_User"" = T3.""USER_CODE""
    WHERE 
     --T0.""ShipDate"" = '20170214'
    --t0.""LineStatus""='O'
    t1.""DocEntry"" = {0}
    AND T0.""U_QtySum"" > 0
";



$SQLQUERY_BIN_BATCH = "SELECT DISTINCT T2.""ItemCode"", T3.""WhsCode"", T4.""BinAbs"", T2.""DistNumber"", T4.""OnHandQty""-IFNULL(T3.""CommitQty"",0) ""Quantity""
FROM OBTN T2
INNER JOIN OBTQ T3 ON T2.""AbsEntry"" = T3.""MdAbsEntry"" 
INNER JOIN OBBQ T4 ON T2.""AbsEntry"" = T4.""SnBMDAbs"" AND T3.""WhsCode"" = T4.""WhsCode""
LEFT JOIN (SELECT T0.""ItemCode"", Coalesce(T1.""DistNumber"", T2.""DistNumber"") AS ""BatchNo"",  T0.""Quantity"", T0.""WhsCode"" 
                  FROM INC3 T0
                  LEFT JOIN ODBN T1 ON T0.""ObjAbs"" = T1.""AbsEntry"" AND T0.""ObjId"" = T1.""ObjType""
                  LEFT JOIN OBTN T2 ON T0.""ObjAbs"" = T2.""AbsEntry"" AND T0.""ObjId"" = T2.""ObjType""
                  WHERE ""DocEntry"" = 1  AND ""ObjId"" IN ('10000044','10000068')) T5 ON T2.""ItemCode"" = T5.""ItemCode"" AND T3.""WhsCode"" = T5.""WhsCode"" AND T2.""DistNumber"" = T5.""BatchNo""
WHERE 
T4.""OnHandQty""-IFNULL(T3.""CommitQty"",0) > 0
AND
T2.""ItemCode"" IN ({0})
ORDER BY T2.""ItemCode"", T3.""WhsCode""";


$code = $Company.Connect()

if($code -eq 0) {
    
    Write-Host -BackgroundColor Green 'Connection successful'

    $recordSetPickLists = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
    $recordSetPickLists.DoQuery($SQL_PICK_LIST);
    while(!$recordSetPickLists.EoF)
    {
        
        $ToDoEntry = $recordSetPickLists.Fields.Item('DocEntry').Value;
        #Query
        $recordSet = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $quryPickOrderList = [string]::Format($SQLQUERY_PICK_ORDER_LIST,$ToDoEntry);
        $recordSet.DoQuery($quryPickOrderList);
    
  
        $ppPositionsCount = $recordSet.RecordCount
        if($ppPositionsCount -gt 0){
            $msg = [string]::format('Pozycji do dodania na listę pobrań: {0}',$ppPositionsCount)
            Write-Host -BackgroundColor Blue $msg
        

            $prevDocEntry = 0;
            $dictionary = New-Object 'System.Collections.Generic.Dictionary[int,System.Collections.Generic.Dictionary[int,double]]'
            $dictionaryItemCodeWhsCode = New-Object 'System.Collections.Generic.Dictionary[int,System.Collections.Generic.Dictionary[int,psobject]]'
            $dictionaryLineToRow = New-Object 'System.Collections.Generic.Dictionary[int,System.Collections.Generic.Dictionary[int,int]]'
            Write-Host 'Przygotowywanie danych o pozycjach do pobrania'
            while(!$recordSet.EoF){
                $docEntry = $recordSet.Fields.Item('DocEntry').Value;
                $lineNum = $recordSet.Fields.Item('LineNum').Value;
                $rowNum = $recordSet.Fields.Item('RowNum').Value;
                $quantity = $recordSet.Fields.Item('Quantity').Value;
                $whsCode = $recordSet.Fields.Item('WhsCode').Value;
                $itemCode = $recordSet.Fields.Item('ItemCode').Value;
                $refNum = $recordSet.Fields.Item('Ref').Value;
                $ownerCode = $recordSet.Fields.Item('USERID').Value;

                if($docEntry -ne $prevDocEntry) {
                    if($prevDocEntry -ne 0){
                        $dictionary.Add($prevDocEntry, $quantityDictionary);
                        $dictionaryLineToRow.Add($prevDocEntry, $lineToRowDictionary);
                        $dictionaryItemCodeWhsCode.Add($prevDocEntry,$itemWhsDictionary);
                        #$manufacturingOrders += (,$dictionary)
                    }
                    $quantityDictionary = New-Object 'System.Collections.Generic.Dictionary[int,double]'
                    $lineToRowDictionary = New-Object 'System.Collections.Generic.Dictionary[int,int]'
                    $itemWhsDictionary = New-Object 'System.Collections.Generic.Dictionary[int,psobject]';
                }

                $quantityDictionary.Add($rowNum,$quantity)
                $lineToRowDictionary.Add($lineNum,$rowNum);
                $itemWhsObject = [psobject]@{
                        ItemCode = $itemCode;
                        WhsCode = $whsCode;
                        LineNum = $lineNum;
                    };

                $itemWhsDictionary.Add($rowNum, $itemWhsObject);
                $prevDocEntry = $docEntry;
            
            
                $recordSet.MoveNext();
            }
        
        
            $dictionary.Add($prevDocEntry, $quantityDictionary);
            $dictionaryLineToRow.Add($prevDocEntry, $lineToRowDictionary);
            $dictionaryItemCodeWhsCode.Add($prevDocEntry,$itemWhsDictionary);

            #Przygotowanie zapytania dla numerów partii
            $sql_param_items_in = "";
            foreach($docEntry in $dictionaryItemCodeWhsCode.Keys)
            {
                $orderLines = $dictionaryItemCodeWhsCode[$docEntry];

                $countLines = $orderLines.Count
                $k = 0;
                foreach($rowNum in $orderLines.Keys)
                {
                    $itemCode = $orderLines[$rowNum].ItemCode;
                    if ($k -eq $countLines -1 )
                    {
                        $sql_param_items_in += "'" + $itemCode + "'";
                    } else {
                        $sql_param_items_in += "'" + $itemCode + "',";
                    }

                    $k++;
                }    

            }
        
            $recordSetBinBatch = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            $query = [string]::Format($SQLQUERY_BIN_BATCH, $sql_param_items_in);
            $recordSetBinBatch.DoQuery($query);

            $binBatchTable = New-Object 'System.Collections.Generic.Dictionary[string,psobject]';

            $prevKey = '';
            $binBatchTable = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[psobject]]';
            $binBatchObjectsList = New-Object 'System.Collections.Generic.List[psobject]'
            
            Write-Host 'Przygtowanie danych o numerach partii oraz lokalizacjach'
            while(!$recordSetBinBatch.EoF){

                $itemCode = $recordSetBinBatch.Fields.Item('ItemCode').Value;
                $WhsCode = $recordSetBinBatch.Fields.Item('WhsCode').Value;
                $key = $itemCode + '___' + $WhsCode;

                $binBatchObject = [psobject]@{
                    BinAbs = $recordSetBinBatch.Fields.Item('BinAbs').Value;
                    DistNumber = $recordSetBinBatch.Fields.Item('DistNumber').Value;
                    Quantity = $recordSetBinBatch.Fields.Item('Quantity').Value;
                    OrderQty = 0;
                    PickQty = 0;
                };

                if($key -ne $prevKey) {
                    if($prevKey -ne ''){
                        $binBatchTable.Add($prevKey,$binBatchObjectsList);
                    }
                    $binBatchObjectsList = New-Object 'System.Collections.Generic.List[psobject]'
                }

                $binBatchObjectsList.Add($binBatchObject);
            
                $prevKey = $key;
                $recordSetBinBatch.MoveNext();
            }
        
        
            $binBatchTable.Add($prevKey,$binBatchObjectsList);

            $ordersBatchLoopIndex = 0
            try {
                #Aktualizacja zleceń - partie
                Write-Host 'Aktualizacja zleceń'
                foreach($docEntry in $dictionary.Keys)
                {
                    $order = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oOrders);
            
                    $x = $order.GetByKey($docEntry);

                    $orderLines = $dictionary[$docEntry]

                    foreach($rowNum in $orderLines.Keys)
                    {
                        $msg = [string]::format('{0}/{1}',$ordersBatchLoopIndex+1,$ppPositionsCount)
                        Write-Host $msg
                        $order.Lines.SetCurrentLine($rowNum);
                
                        $lineBaseEntry = $docEntry
                        $lineBaseLineNum = $order.Lines.LineNum; # $lineNum

                        $quantityToBePicked = $orderLines[$rowNum];
                        $pickedQuantity = 0;
                        $itemCode = $order.Lines.ItemCode
                        $WhsCode = $order.Lines.WarehouseCode
                
                        $key = $itemCode + '___' + $WhsCode;

                
                        $positionsToChoseFrom = $binBatchTable[$key];

                        if($positionsToChoseFrom.Count -gt 0) {
                            #region uzupełnienie lokalizacji oraz partii do lini
                            $batchLN = 0;
                            while($pickedQuantity -lt $quantityToBePicked) {
                            #batch
                                $openQuantityToBePicked = $quantityToBePicked - $pickedQuantity;
                
                                for($i=0;$i -lt $positionsToChoseFrom.Count; $i++)
                                {
                                    $openPosition = $positionsToChoseFrom[$i];
                                    $openQty = $openPosition.Quantity - $openPosition.OrderQty
                                    if($openQty -gt 0){
                                        break;
                                    }
                                }

                                #throw error not enought quantity
                                if($openQty -eq 0){
                                    $ms = [string]::Format("Zlecenie sprzedaży {0} nie zostało zaktualizowane`n`nNa magazynie {1} nie ma wystarczającej ilości dla indeksu: {2}",$order.DocNum,$WhsCode, $itemCode); 
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                    #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Wydanie nie zostało zaktualizowane"); 
                                    exit;
                            
                                }

                                if($openQty -ge $openQuantityToBePicked)
                                {
                                    $qty = $openQuantityToBePicked;

                                } else {
                                    $qty = $openQty;

                                }


                                $countBatchNumbersForLine = $order.Lines.BatchNumbers.Count;
                                $batchAlreadyExists = $false
                                for($b = 0; $b -lt $countBatchNumbersForLine; $b++)
                                {
                                    $order.Lines.BatchNumbers.SetCurrentLine($b);
                                    if($order.Lines.BatchNumbers.BatchNumber -eq $openPosition.DistNumber)
                                    {
                                        $batchAlreadyExists = $true;
                                        break;
                                    }
                                }
                        
                                if($batchAlreadyExists){
                                    $order.Lines.BatchNumbers.Quantity += $qty;

                                } else {
                                    $order.Lines.BatchNumbers.SetCurrentLine($countBatchNumbersForLine-1);

                                    if($order.Lines.BatchNumbers.BatchNumber -ne '')
                                    {
                                        $order.Lines.BatchNumbers.Add()
                                    }
                                    $order.Lines.BatchNumbers.BatchNumber = $openPosition.DistNumber;
                                    $order.Lines.BatchNumbers.BaseLineNumber = $order.Lines.LineNum
                                    $order.Lines.BatchNumbers.Quantity = $qty;
                                  #  $order.Lines.BatchNumbers.Add()
                                }


                                $openPosition.OrderQty += $qty;
                                $openQuantityToBePicked -= $qty;
                                $pickedQuantity += $qty;
                          
                            }
                
                        }    


                        $ordersBatchLoopIndex++;
                    }

                    $message = $order.Update();
                
                    if($message -lt 0)
                    {
                        $err= $Company.GetLastErrorDescription();
                        $ms = [string]::Format("Zlecenie sprzedaży {0} nie zostało zaktualizowane`n`nSzczegóły: {1}",$order.DocNum,$err); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                        #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Wydanie nie zostało zaktualizowane"); 
                        exit;
                    } 
                }
            } Catch {
               $err=$_.Exception.Message;
               $ms = [string]::Format("Zlecenie sprzedaży {0} nie zostało zaktualizowane`n`nSzczegóły: {1}",$order.DocNum,$err); 
               Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
               #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Zlecenie sprzedaży nie zostało zaktualizowane"); 
               exit;
            }
        

        
            Write-Host 'Utworzenie listy pobrania';
            $pickList = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oPickLists);
        
               
            try {
                $pickList.UserFields.Fields.Item('U_ZW').Value = $refNum;
                $pickList.Name = $ownerCode 
                $pickList.UseBaseUnits = [SAPbobsCOM.BoYesNoEnum]::tYES;
                foreach($docEntry in $dictionary.Keys)
                {
                    $orderLines = $dictionary[$docEntry]

                    foreach($rowNum in $orderLines.Keys)
                    {
                       $pickList.Lines.BaseObjectType = '17'
                       $pickList.Lines.OrderEntry = $docEntry
                       $pickList.Lines.OrderRowID = $dictionaryItemCodeWhsCode[$docEntry][$rowNum].LineNum;   
                       $pickList.Lines.ReleasedQuantity = $orderLines[$rowNum];
                       $pickList.Lines.Add()

                    }

                }

            
                $retval = $pickList.Add();
            
                if($retVal -ne 0) 
                {    
	                $err= $Company.GetLastErrorDescription();
                    $ms = [string]::Format("Lista pobrań nie została utworzona.`n`nSzczegóły: {0}",$err); 
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Lista pobrań nie została utworzona"); 
                    exit;
                }
            
                $absEntry = $Company.GetNewObjectKey();

                $pickList = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oPickLists);
                $x = $pickList.GetByKey($absEntry);
          
             
            } Catch {
               $err=$_.Exception.Message;
               $ms = [string]::Format("Lista pobrań nie została utworzona.`n`nSzczegóły: {0}",$err); 
               Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
               #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Lista pobrań nie została utworzona"); 
               exit;
            }

            if($absEntry -gt 0){

            
                $count = $pickList.Lines.Count;
                $msg = [string]::format('Uzupełenienie listy pobrania. Pozycji do uzupełnienia:{0}',$count);
                Write-Host $msg
                for($j = 0;$j -lt $count;$j++){
                    $msg = [string]::format('{0}/{1}',$j+1,$count)
                    Write-Host $msg

                    $pickList.Lines.SetCurrentLine($j);
                
                    $lineBaseEntry = $pickList.Lines.OrderEntry;
                    $lineBaseLineNum = $pickList.Lines.OrderRowID;
                    $orderRowNum = $dictionaryLineToRow[$lineBaseEntry][$lineBaseLineNum];


                    $quantityToBePicked = $dictionary[$lineBaseEntry][$orderRowNum];
                    $pickedQuantity = 0;
                    $itemCode = $dictionaryItemCodeWhsCode[$lineBaseEntry][$orderRowNum].ItemCode;
                    $WhsCode = $dictionaryItemCodeWhsCode[$lineBaseEntry][$orderRowNum].WhsCode;
                
                    $key = $itemCode + '___' + $WhsCode;

                
                    $positionsToChoseFrom = $binBatchTable[$key];

                    if($positionsToChoseFrom.Count -gt 0) {
                        #region uzupełnienie lokalizacji oraz partii do lini
                        $batchLN = 0;
                        while($pickedQuantity -lt $quantityToBePicked) {
                        #batch
                            $openQuantityToBePicked = $quantityToBePicked - $pickedQuantity;
                
                            for($i=0;$i -lt $positionsToChoseFrom.Count; $i++)
                            {
                                $openPosition = $positionsToChoseFrom[$i];
                                $openQty = $openPosition.Quantity - $openPosition.PickQty
                                if($openQty -gt 0){
                                    break;
                                }
                            }

                            #throw error not enought quantity
                            if($openQty -eq 0){
                                $ms = [string]::Format("Lista Pobrań {0} nie została zaktualizowana`n`nNa magazynie {1} nie ma wystarczającej ilości dla indeksu: {2}",$pickList.AbsoluteEntry,$WhsCode, $itemCode); 
                                Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Wydanie nie zostało zaktualizowane"); 
                                exit;
                            
                            }

                            if($openPosition.Quantity -ge $openQuantityToBePicked)
                            {
                                $qty = $openQuantityToBePicked;

                            } else {
                                $qty = $openQty;

                            }

                            $pickList.Lines.BatchNumbers.BatchNumber = $openPosition.DistNumber;
                            $pickList.Lines.BatchNumbers.BaseLineNumber = $pickList.Lines.LineNumber;
                            $pickList.Lines.BatchNumbers.Quantity = $qty;
                            $pickList.Lines.BatchNumbers.Add()
                        

                            $pickList.Lines.BinAllocations.BinAbsEntry = $openPosition.BinAbs
                            $pickList.Lines.BinAllocations.Quantity = $qty;
                            $pickList.Lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN;
                            $pickList.Lines.BinAllocations.BaseLineNumber = $pickList.Lines.LineNumber;
                            $pickList.Lines.BinAllocations.Add();
                            $batchLN++;


                            $openPosition.PickQty += $qty;
                            $openQuantityToBePicked -= $qty;
                            $pickedQuantity += $qty;
  
                           
                        }
                
                    }           
                        #endregion
                    #endregion
               }    

                    
                $message = $pickList.Update();
                if($message -lt 0)
                {
                    $err= $Company.GetLastErrorDescription();
                    $ms = [string]::Format("Lista pobrań {0} nie zostało zaktualizowane`n`nSzczegóły: {1}",$absEntry,$err); 
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Wydanie nie zostało zaktualizowane"); 
                    exit;
                } 
            
                $ms = [string]::Format("Lista pobrań została poprawnie utworzona. Numer dokumentu: {0}",$absEntry); 
                Write-Host -BackgroundColor Green $ms
                #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($ms,[Microsoft.VisualBasic.MsgBoxStyle]::Information,"Zakończono przetwarzanie");

               # $msg = [string]::format('Aktualizacja MOR3');
               # Write-Host $msg
               # $queryManager.CommandText=$SQLQUERY_UPDATE;
               # $queryManager.AddParameter("docEntry",$docentryPickOrder);
               # $rs=$queryManager.Execute($pfcCompany.Token);  
               # 
               # $msg = [string]::format('Przetwarzanie zakończone');
               # Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue $msg

            }
        } else 
        {
            $msg = [string]::format('Brak pozycji do wydania')
            Write-Host -BackgroundColor Blue $msg
        }
   
        $recordSetPickLists.MoveNext();
    }  
}
else
{
    $msg = [string]::format("Bład połączenia.")
    Write-Host -BackgroundColor Red -ForegroundColor White $msg
    #$x = [Microsoft.VisualBasic.Interaction]::MsgBox($msg,[Microsoft.VisualBasic.MsgBoxStyle]::Critical,"Bład połączenia do SAP'a.");
}
exit;