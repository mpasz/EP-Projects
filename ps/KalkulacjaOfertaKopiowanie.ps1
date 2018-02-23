
[Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

function updateZOF($pfcCompany, $dictionaryUpdateZof ) {
    try {
        
        $countLines = $dictionaryUpdateZof.Count
        if($dictionaryUpdateZof.Count -gt 0){
            $recordSetZof = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            
            foreach ($key in $dictionaryUpdateZof.Keys) {
                $status =  $dictionaryUpdateZof[$key];
                $SQL_UPDATE_ZOF = [string]::Format("UPDATE ""@CT_ZOF_N"" SET ""U_Copy""='{0}' WHERE ""DocEntry"" = {1};",$status,$key);
                $dummy = $recordSetZof.DoQuery($SQL_UPDATE_ZOF);
            }
        }
       

    } catch { 
        continue; 
    }
}


function setStatus($dictionaryUpdateZof, $ZofDocEntry, $status){
    
    if($dictionaryUpdateZof.ContainsKey($ZofDocEntry)){
        if($status -eq -1){
           $dictionaryUpdateZof[$ZofDocEntry] = $status
        }
    } else {
            $dictionaryUpdateZof.Add($ZofDocEntry,$status);
    }
}

function createCopy($Company) {

    
    $ZOF_UDO_CODE = 'CT_ZOF';
  
    #region sql queries
    $SQL_ZOFS = "SELECT T0.""DocEntry"", 
	(SELECT MAX(SUBSTRING(T.""U_InqNo"",6,2)) AS ""YY"" FROM ""@CT_ZOF_N"" T 
	WHERE SUBSTRING(T.""U_InqNo"",1,4) = SUBSTRING(T0.""U_InqNo"",1,4)
	 AND SUBSTRING(T.""U_InqNo"",9,4) = SUBSTRING(T0.""U_InqNo"",9,4)) AS ""YY"" 
	FROM ""@CT_ZOF_N"" T0 WHERE CAST(IFNULL(T0.""U_Copy"",'N') AS VARCHAR(1)) = 'T' ORDER BY T0.""DocEntry"" " ;
    
    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
    VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),'{0}','{1}','{2}','{3}',CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'KalkulacjaOfertaKopiowanie.ps1','F')";

    #endregion 

    $code = $Company.Connected
    if ($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'

        $recordSetZOFs = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetZOFs.DoQuery($SQL_ZOFS);
        $recordSetLog = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")

        #region zofs
        $ppPositionsCount = $recordSetZOFs.RecordCount
        $msg = [string]::format('Dokumentów do kopiowania: {0}', $ppPositionsCount)
        Write-Host -BackgroundColor Blue $msg

        $prevKey = '_';
        $dictionary = New-Object 'System.Collections.Generic.Dictionary[string,string]'
        $dictionaryUpdateZof = New-Object 'System.Collections.Generic.Dictionary[string,string]'

        Write-Host 'Przygotowywanie danych o kalkulacjach'
        while (!$recordSetZOFs.EoF) {
           $DocEntry = $recordSetZOFs.Fields.Item('DocEntry').Value;
           $yy = $recordSetZOFs.Fields.Item('YY').Value;
           $dictionary.Add($DocEntry,$yy);
           $recordSetZOFs.MoveNext();
        }
        #endregion
     
        try {

            #region zof documents
            $cs = $Company.GetCompanyService();
            $zofDocEntryList = New-Object 'System.Collections.Generic.List[string]';
            #Dodanie kalkulacji
            Write-Host 'Kopiowanie ZOF'
            foreach ($docEntry in $dictionary.Keys) {
                try {
                    $ZofDocEntry = $docEntry;

                    $gs = $cs.GetGeneralService($ZOF_UDO_CODE);
                    
                    $generalParams = $gs.GetDataInterface([SAPbobsCOM.GeneralServiceDataInterfaces]::gsGeneralDataParams)
                    $generalParams.SetProperty('DocEntry', $ZofDocEntry);
                    $zofOrg = $gs.GetByParams($generalParams);
                    $zofNew = $gs.GetDataInterface([SAPbobsCOM.GeneralServiceDataInterfaces]::gsGeneralData);
                    
                    $xml = [System.Xml.Linq.XDocument]::Parse($zofOrg.ToXMLString());
                    $zofNew.FromXMLString($xml);

                    $U_InqNo = $zofNew.GetProperty('U_InqNo');
                    
                    $yy = $dictionary[$ZofDocEntry];

                    $InqNoSplit =  $U_InqNo.Split('/');
                    $counter = 0;
                    if(($InqNoSplit.Count -eq 3) -and ([int]::TryParse($yy,[ref] $counter))){
                        $counter++;
                        $newInqNo = $InqNoSplit[0] + '/' + ([string] $counter).PadLeft(2,'0') + '/' + $InqNoSplit[2]
    
                    } else {
                        $newInqNo = $U_InqNo
                    }

                    $zofNew.SetProperty('U_InqNo',$newInqNo);
                    $zofNew.SetProperty('DocNum', '')
                    $zofNew.SetProperty('U_DocDate', '')
                    $zofNew.SetProperty('U_InqDate', '')
                    $zofNew.SetProperty('U_ExpDate', '')
                    $zofNew.SetProperty('U_InqStatus', '0')
                    $zofNew.SetProperty('U_Copy', 'N')
                    #$zofNew.ToXMLString()
                    
                    $x = $gs.Add($zofNew); 
                    $zofNewDocEntry = $Company.GetNewObjectKey();
                    $zofDocEntryList.Add($zofNewDocEntry);
                    setStatus $dictionaryUpdateZof $ZofDocEntry 'N'
                 
                }
                Catch {
                    setStatus $dictionaryUpdateZof $ZofDocEntry 'T'
                    $err = $_.Exception.Message;
                    $actionDescription = 'dodana';
                    $keyName = 'ZofDocEntry';
                    $keyValue = $ZofDocEntry;


                    $ms = [string]::Format("Zof nie zosta³ skopiowany {0}:{1}`n`nSzczegó³y: {2}", $actionDescription, $key, $err); 
                    
                    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                    $logQuery = [string]::Format($SQL_INSERT_LOG, $ZOF_UDO_CODE, $keyName, $keyValue, $ms.Replace("'","''"));
                    $recordSetLog.DoQuery($logQuery);

                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    continue;
                } 
            }

            updateZOF $pfcCompany $dictionaryUpdateZof
        }
        Catch {
            
            $err = $_.Exception.Message;
            $ms = [string]::Format("Wyst¹pi³ b³¹d: {0}", $err); 
            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
            updateZOF $pfcCompany $dictionaryUpdateZof
        }
    }
    else {
        $msg = [string]::format("B³ad po³¹czenia.")
        Write-Host -BackgroundColor Red -ForegroundColor White $msg
        exit;
    }
}