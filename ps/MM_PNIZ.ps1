function createMM($Company){

$lErrCode = 0
$sErrMsg = ""
$DATABASE_NAME = 'SBOELECTROPOLI' 

$SQL_MM_LIST = "SELECT * FROM ""@PNIZ"" WHERE ""U_STATUS"" = 'C' AND IFNULL(""U_QTY"",0) > 0" ;

$SQL_MM_UPDATE_STATUS = " 
 UPDATE ""@PNIZ"" SET ""U_STATUS"" = 'S', ""U_TargetMM"" = '{0}'  WHERE ""Code"" = '{1}'"
 
 $SQL_MM_UPDATE_STATUS2="  update ""@CT_WMS_OSTU"" set ""U_IloscOrig"" =""U_IloscOrig""-""U_IloscZlych"",  ""U_IloscZlych""=0 ,""U_StatusSU""= case when ""U_IloscOrig""-""U_IloscZlych""=0 then '3' else ""U_StatusSU"" end 
 where ""U_Code""= (select ""Name"" from ""@PNIZ""  where ""Code"" = '{0}')"
# {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
$SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
    VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),'{0}','{1}','{2}','{3}',CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'MM_PNIZ.ps1','F')";

$code = $Company.Connected
if($code -eq $true) {
    try{  
        Write-Host -BackgroundColor Green 'Connection successful'
        $recordSetLog = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetUpdate = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSet = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSet.DoQuery($SQL_MM_LIST);
    
  
        $ppPositionsCount = $recordSet.RecordCount
        if($ppPositionsCount -gt 0){
            $msg = [string]::format('Pozycji do dodania przesunięcia: {0}',$ppPositionsCount)
            Write-Host -BackgroundColor Blue $msg

            $mmList = New-Object 'System.Collections.Generic.List[psobject]'
            while(!$recordSet.EoF){
                $code = $recordSet.Fields.Item('Code').Value;
                $itemCode = $recordSet.Fields.Item('U_ItemCode').Value;
                $fromWhsCode = $recordSet.Fields.Item('U_FROMWHS').Value;
                $toWhsCode = $recordSet.Fields.Item('U_TOWHSCODE').Value;
                $distNumber = $recordSet.Fields.Item('U_DistNumber').Value;
                $fromBinAbs = $recordSet.Fields.Item('U_FromBinAbs').Value;
                $toBinAbs = $recordSet.Fields.Item('U_ToBinAbs').Value;
                $wada = $recordSet.Fields.Item('U_WADA').Value;
                $qty  = $recordSet.Fields.Item('U_QTY').Value;

                $line = [psobject]@{
                    code =$code;                                           
                    itemCode = $itemCode;                                         
                    fromWhsCode = $fromWhsCode;                                      
                    toWhsCode = $toWhsCode;                                        
                    distNumber = $distNumber;                                       
                    fromBinAbs =$fromBinAbs;                                       
                    toBinAbs =$toBinAbs                                         
                    wada = $wada;                                           
                    qty = $qty; 
                };
                
                $mmList.Add($line);
                $recordSet.MoveNext();
            }
        
        
            foreach($mmLine in $mmList)
            {
                try {
                        $mm = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oStockTransfer);
                        $mm.FromWarehouse = $mmLine.fromWhsCode
                        $mm.ToWarehouse = $mmLine.toWhsCode
                        $mm.UserFields.Fields.Item("U_Guid").Value='1'
                        $mm.Lines.ItemCode = $mmLine.itemCode
                        $mm.Lines.FromWarehouseCode = $mmLine.fromWhsCode
                        $mm.Lines.WarehouseCode = $mmLine.toWhsCode
                        $mm.Lines.Quantity = $mmLine.qty
                
                
                        #batchnumber bins
                        $qty = $mmLine.qty
                        $batchLN = 0
                        $mm.Lines.BatchNumbers.BatchNumber = $mmLine.distNumber
                        $mm.Lines.BatchNumbers.BaseLineNumber = $mm.Lines.LineNum
                        $mm.Lines.BatchNumbers.Quantity = $qty;
                        $mm.Lines.UserFields.Fields.Item('U_Technology').Value = $mmLine.wada
                        #$mm.Lines.BatchNumbers.Add() 
                        

                        $mm.Lines.BinAllocations.BinAbsEntry = $mmLine.fromBinAbs
                        $mm.Lines.BinAllocations.BinActionType = [SAPbobsCOM.BinActionTypeEnum]::batFromWarehouse
                        $mm.Lines.BinAllocations.Quantity = $qty;
                        $mm.Lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN;
                        $mm.Lines.BinAllocations.BaseLineNumber = $mm.Lines.LineNum
                        $mm.Lines.BinAllocations.Add();

                        $mm.Lines.BinAllocations.BinAbsEntry = $mmLine.toBinAbs
                        $mm.Lines.BinAllocations.BinActionType = [SAPbobsCOM.BinActionTypeEnum]::batToWarehouse
                        $mm.Lines.BinAllocations.Quantity = $qty;
                        $mm.Lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN;
                        $mm.Lines.BinAllocations.BaseLineNumber = $mm.Lines.LineNum
                      #  $mm.Lines.BinAllocations.Add();
                        $batchLN++;

                        $addStatus = $mm.Add();
               
                        if(($addStatus -lt 0) -and ($addStatus -ne -1116))
                        {
                            $err= $Company.GetLastErrorDescription();
                            $ms = [string]::Format("Dokument przesunięcia nie został dodany`n`nSzczegóły:`nCode: {0}`n{1}",$mmLine.code,$err); 
                            # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                            $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oStockTransfer,'DocEntry','',$ms);
                            $recordSetLog.DoQuery($logQuery);
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            continue;
                        } 
                        $ms = [string]::Format("Dokument przesunięcia został poprawnie dodany: {0}",$mm.DocNum);  
                        Write-Host -BackgroundColor Green $ms
                        $updateQuery = [string]::Format($SQL_MM_UPDATE_STATUS,$Company.GetNewObjectKey(),$mmLine.code);
                       # $updateQuery2 = [string]::Format($SQL_MM_UPDATE_STATUS2,$mmLine.code);
                        $recordSetUpdate.DoQuery($updateQuery);
                       # $recordSetUpdate.DoQuery($updateQuery2);
                    } Catch {
                       $err=$_.Exception.Message;
                       $ms = [string]::Format("Dokument przesunięcia nie został dodany`n`nSzczegóły:`nCode: {0}`n{1}",$mmLine.code,$err);  
                       # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                       $logQuery = [string]::Format($SQL_INSERT_LOG,[SAPbobsCOM.BoObjectTypes]::oStockTransfer,'DocEntry','',$ms);
                       $recordSetLog.DoQuery($logQuery);
                       Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                       continue;
                    }
            }
            Start-Sleep -Seconds 10
        } else {
             Start-Sleep -Seconds 10
        }
    } catch {
        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
        $err=$_.Exception.Message;
        $logQuery = [string]::Format($SQL_INSERT_LOG,'','','',$err);

    }  
}
else
{
    $msg = [string]::format("Bład połączenia.")
    Write-Host -BackgroundColor Red -ForegroundColor White $msg
    logConnectionError($DATABASE_NAME,$msg,'MM_PNIZ.ps1')
}
}