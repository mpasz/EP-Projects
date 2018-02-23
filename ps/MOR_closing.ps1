function CloseMORS($Company){
    
    $lErrCode = 0
    $sErrMsg = ""
    $DATABASE_NAME = 'SBOELECTROPOLI' 
    
    $SQL_MOR_LIST = "select t0.""DocEntry"",t1.""DocNum"",t1.""U_Status"" from  CT_MORS_TO_CLOSE t0
    inner join ""@CT_PF_OMOR"" t1 on t0.""DocEntry""=t1.""DocEntry""" ;
    
   
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
    
            VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),@Object,@Key_Name,@Key_Value,@Remarks,CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'PickOrderPickReceipt.ps1','F')";
     
    $code = $Company.SAPCompany.Connected
    if($code -eq $true) {
        try{  
            Write-Host -BackgroundColor Green 'Connection successful'
            $recordSetLog = $Company.SAPCompany.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            $recordSetUpdate = $Company.SAPCompany.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            $recordSet = $Company.SAPCompany.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
       $recordSet.DoQuery($SQL_MOR_LIST);
      
            $ppPositionsCount = $recordSet.RecordCount
            if($ppPositionsCount -gt 0){
                $msg = [string]::format('Pozycji do dodania Zamknięcia: {0}',$ppPositionsCount)
                Write-Host -BackgroundColor Blue $msg
    
                $morList = New-Object 'System.Collections.Generic.List[psobject]'
                while(!$recordSet.EoF){
                    $DocEntry = $recordSet.Fields.Item('DocEntry').Value;
                    $DocNum = $recordSet.Fields.Item('DocNum').Value;
                    $status = $recordSet.Fields.Item('U_Status').Value;
               
    
                    $line = [psobject]@{
                        DocEntry =$DocEntry;                                           
                        DocNum = $DocNum;                                         
                        status = $status;                                      
                       
                    };
                    
                    $morList.Add($line);
                    $recordSet.MoveNext();
                }
                $queryManagerLog= New-Object CompuTec.Core.DI.Database.QueryManager
                $queryManagerLog.CommandText = $SQL_INSERT_LOG;
            
                foreach($mmLine in $morList)
                {
                    try {
                        $mo = [CompuTec.ProcessForce.API.Core.Factory.UdoFactoryClass]::CreateDocument($pfcCompany.Token ,[CompuTec.ProcessForce.API.Core.ObjectTypes]::ManufacturingOrder);
                        $mo.GetByKey($mmline.DocEntry)
                        $started=$false;
                        if($mmLine.status -ne 'FI')
                        {
                            $mo.U_Status=5;
                            $pfcCompany.StartTransaction();
                            $started=$true;
                          $update =  $mo.Update();
                            if($update -lt 0)
                            {
                                      if($pfcCompany.InTransaction){
                                    $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); }
                                    $err= $Company.GetLastErrorDescription();
                                $ms = [string]::Format("Zlecenie nie moze być zakonczone   `n`nSzczegóły:`nCode: {0}`n{1}",$mmLine.DocNum,$err); 
                                # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                                
                              
                                $Object = 'MORClose';
                                $KeyName = 'MORDocEntry';
                                $KeyValue = $mmline.DocEntry;
                                $Remarks = $ms;


                                $queryManagerLog.ClearParameters();
                                $queryManagerLog.AddParameter("Object",$Object);
                                $queryManagerLog.AddParameter("Key_Name",$KeyName);
                                $queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                $queryManagerLog.AddParameter("Remarks",$Remarks);
                                $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                
                                Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                          
                                continue;
                            } 

                        }
                             $mo.U_Status=6;
                            
                   if($started -eq $false)
                   {
                    $pfcCompany.StartTransaction();
                    $started=$true;
                   }
                   $update = $mo.Update();
                            if($update -lt 0)
                            {   if($pfcCompany.InTransaction){
                                    $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); }
                                $err= $Company.GetLastErrorDescription();
                                $ms = [string]::Format("Zlecenie nie moze być zamkniete `n`nSzczegóły:`nCode: {0}`n{1}",$mmLine.DocNum,$err); 
                                # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                               
                                $Object = 'MORClose';
                                $KeyName = 'MORDocEntry';
                                $KeyValue = $mmline.DocEntry;
                                $Remarks = $ms;


                                $queryManagerLog.ClearParameters();
                                $queryManagerLog.AddParameter("Object",$Object);
                                $queryManagerLog.AddParameter("Key_Name",$KeyName);
                                $queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                $queryManagerLog.AddParameter("Remarks",$Remarks);
                                $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                             
                                continue;
                            } 
                            $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Commit);
                            $ms = [string]::Format("Zlecenie zostało poprawnie zamkniete: {0}",$mmLine.DocNum);  
                            Write-Host -BackgroundColor Green $ms
                             
                        } Catch {

                        if($pfcCompany.InTransaction){
                                    $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); }
                           $err=$_.Exception.Message;
                           $ms = [string]::Format("Zlecenie nie moze być zamkniete�y:`nCode: {0}`n{1}",$mmLine.DocNum,$err);  
                           # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                           $Object = 'MORClose';
                           $KeyName = 'MORDocEntry';
                           $KeyValue = $mmline.DocEntry;
                           $Remarks = $ms;


                           $queryManagerLog.ClearParameters();
                           $queryManagerLog.AddParameter("Object",$Object);
                           $queryManagerLog.AddParameter("Key_Name",$KeyName);
                           $queryManagerLog.AddParameter("Key_Value",$KeyValue);
                           $queryManagerLog.AddParameter("Remarks",$Remarks);
                           $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                           ##$recordSetLog.DoQuery($logQuery);
                           Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms 
                           continue;
                        }
                }
                Start-Sleep -Seconds 10
            } else {
                 Start-Sleep -Seconds 10
            }
        } catch {
        if($pfcCompany.InTransaction){
                                    $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); }
            # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
            $err=$_.Exception.Message;
            
            $Object = 'MORClose';
            $KeyName = 'MORDocEntry';
            $KeyValue = $mmline.DocEntry;
            $Remarks = $ms;
            $ms = [string]::Format("Zlecenie nie moze być zamkniete�y:`nCode: {0}`n{1}",$mmLine.code,$err);  

            $queryManagerLog.ClearParameters();
            $queryManagerLog.AddParameter("Object",$Object);
            $queryManagerLog.AddParameter("Key_Name",$KeyName);
            $queryManagerLog.AddParameter("Key_Value",$KeyValue);
            $queryManagerLog.AddParameter("Remarks",$Remarks);
            $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
    
        }  
    }
    else
    {
        $msg = [string]::format("Bład połączenia.")
        Write-Host -BackgroundColor Red -ForegroundColor White $msg
        logConnectionError($DATABASE_NAME,$msg,'MM_PNIZ.ps1')
    }
    }