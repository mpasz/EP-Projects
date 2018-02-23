function updateZOF($pfcCompany, $dictionaryUpdateZof ) {
    try {
        
        $countLines = $dictionaryUpdateZof.Count
        if($dictionaryUpdateZof.Count -gt 0){
            $recordSetZof = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            
            foreach ($key in $dictionaryUpdateZof.Keys) {
                $status =  $dictionaryUpdateZof[$key];
                $SQL_UPDATE_ZOF = [string]::Format("UPDATE ""@CT_ZOF_N"" SET ""U_InqStatus""='{0}' WHERE ""DocEntry"" = {1};",$status,$key);
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

function createCalcOffer($Company) {

    
    $CALCULATION_UDO_CODE = 'CT_KOF';
    $CALCULATION_PROCESS_LINES = 'CT_KOF_P1';
    $CALCULATION_TOOLS_LINES = 'CT_KOF_P2';

    #region sql queries
    $SQL_CALCULATIONS = "SELECT DISTINCT
    T0.""DocEntry"",
    T0.""U_CardCode"",
    T0.""U_CardName"",
    T0.""U_InqNo"",
    T1.""LineId"",
    T1.""U_RawDrawNo"",
    T1.""U_FinalDrawNo"",
    '1' AS ""U_Stage"",
    T2.""U_Proces"" AS ""U_Process"",
    T2.""U_ProdLine"" AS ""U_Line"",
    T4.""U_Lack"" AS ""U_Lack"",
    T2.""U_CoverThick"" AS ""U_Size"",
    T2.""U_Surface"" AS ""U_Area"",
    CASE WHEN T2.""U_ProdLine"" IN ('ZNK1','ZNK2') THEN T8.""U_ZnRate""*T4.""U_PriceFactorZn""*T4.""U_DirMatQty""
    ELSE T4.""U_DirMatOf"" END AS ""U_DirMatZl"",
    T4.""U_DirMatQty"" AS ""U_DirMatKg"",
    T4.""U_OtherMatCost"" AS ""U_OthMat"",
    (T2.""U_CoverThick"" * T2.""U_Surface"")/1000 AS ""U_Volume"",
    T3.""U_OperTime"" AS ""U_OperTime"",
    T3.""U_MaskTime"" AS ""U_MaskTime"",
    T4.""U_Payroll"" AS ""U_EmpPrice"",
    T7.""U_EmpEffic"" AS ""U_EmpEffic"",
    T2.""U_ProcMultiply"" AS ""U_PrcMultiple"",
    T2.""U_QtyOnScale"" AS ""U_QtyScale"",
    T4.""U_LineCost"" AS ""U_HookPrice"",
    T7.""U_LineUse"" AS ""U_LineUse"",
    T6.""U_LabCost"" AS ""U_LabMargin"",
    T6.""U_LogCost"" AS ""U_LogMargin"",
    T6.""U_FixCost"" AS ""U_StrMargin"",
    T6.""U_CostMargin"" AS ""U_Margin"",
    T2.""U_PowderPrice"" AS ""U_F1Price"",
    (T2.""U_ShowerPrice1""*T2.""U_WeightShower1"")+(T2.""U_ShowerPrice2""*T2.""U_WeightShower2"")+(T2.""U_ShowerPrice2""*T2.""U_WeightShower2"") AS ""U_NatPriceSum"",
    T8.""U_ZnRate"" AS ""U_ZnRate"",
    T1.""U_Quantity"" AS ""U_SpinYear"",
    T4.""U_LineUse"" AS ""U_Wlpk"",
    T2.""U_HookCost"" AS ""U_HangCost"",
    T2.""U_ProtectSample"" AS ""U_SafeType"",
    T2.""U_ProtectVital"" AS ""U_Vital"",
    T2.""U_QtyOnHang"" AS ""U_HangQty"",
    T2.""U_RotQtyDay"" AS ""U_HangSpin"",
    T8.""U_YearWorkDay"" AS ""U_ProdTime"",
    CEILING(T1.""U_Quantity""/T8.""U_YearWorkDay"") AS ""U_DayQty"",
    T2.""U_HangQty"" AS ""U_HangNeed"",
    T9.""U_Instrument"" AS ""U_AddInsMargin"",
    CASE T0.""U_InqStatus"" WHEN 2 THEN 'A' ELSE 'U' END AS ""Task""
   FROM ""@CT_ZOF_N"" T0
    LEFT OUTER JOIN ""@CT_ZOF_P1"" T1 ON T0.""DocEntry"" = T1.""DocEntry""
    LEFT OUTER JOIN ""@CT_ZOF_P2"" T2 ON T0.""DocEntry"" = T2.""DocEntry"" AND T1.""U_RawDrawNo"" = T2.""U_DrawNoRaw"" AND T1.""LineId"" = T2.""LineId""
    LEFT OUTER JOIN ""@CT_ZOF_P3"" T3 ON T0.""DocEntry"" = T3.""DocEntry"" AND T2.""U_DrawNoRaw"" = T3.""U_DrawNoRaw"" AND T2.""U_Proces"" = T3.""U_Proces"" AND T3.""LineId"" = T2.""LineId""
    LEFT OUTER JOIN ""@CT_OF_JKP"" T4 ON T2.""U_Proces"" = T4.""U_Process"" AND T2.""U_ProdLine"" = T4.""U_Line""
    LEFT OUTER JOIN ""@CT_OF_LPRW"" T5 ON T2.""U_ProdLine"" = T5.""U_Line""
    LEFT OUTER JOIN ""@CT_OF_NK"" T6 ON T2.""U_ProdLine"" = T6.""U_Line""
    LEFT OUTER JOIN ""@CT_OF_ZP"" T7 ON T2.""U_ProdLine"" = T7.""U_Line""
    LEFT OUTER JOIN ""@CT_OF_PD"" T8 ON 1=1
    LEFT OUTER JOIN ""@CT_OF_NKP"" T9 ON 1=1
   WHERE T0.""U_InqStage"" LIKE 'Marketing%' AND ((T0.""U_InqStatus"" = 2 AND T0.""DocEntry"" NOT IN (SELECT DISTINCT IFNULL(""U_ZofNo"",0) FROM ""@CT_KOF_N"")) OR T0.""U_InqStatus"" = 3  )
   ORDER BY T0.""DocEntry"", T1.""LineId"" " ;

   
    $SQLQUERY_OFFERS = "SELECT
    T0.""U_CardCode"" AS ""CardCode"",
    T0.""U_InqNo"",
    CASE WHEN MIN(T2.""U_Proces"") LIKE '%NS' THEN '2' ELSE '1'  END AS ""Branch"",
    CAST(NOW() AS DATE) AS ""DocDate"",
    CAST(NOW() AS DATE) AS ""TaxDate"",
    'SU-00001-00042' AS ""ItemCode"",
    MIN(T1.""U_ItemName"") AS ""Dscription"",
    T1.""U_Quantity"" AS ""Quantity"",
    T1.""U_UoM"" AS ""unitMsr"",
    T1.""U_RawDrawNo"" AS ""DrawRawNo"",
    T1.""U_FinalDrawNo"" AS ""DrawFinalNo"",
    T0.""DocEntry"" AS ""U_ZOFno"",
    CASE T0.""U_InqStatus"" WHEN 2 THEN 'A' ELSE 'U' END AS ""Task""
   FROM ""@CT_ZOF_N"" T0
    LEFT OUTER JOIN ""@CT_ZOF_P1"" T1 ON T0.""DocEntry"" = T1.""DocEntry""
   LEFT OUTER JOIN ""@CT_ZOF_P2"" T2 ON T0.""DocEntry"" = T2.""DocEntry"" AND T1.""U_RawDrawNo"" = T2.""U_DrawNoRaw"" AND T1.""LineId"" = T2.""LineId""
   WHERE (T0.""DocEntry"" NOT IN (SELECT DISTINCT IFNULL(""U_ZOFno"",0) FROM OQUT) AND T0.""U_InqStatus"" = 2) OR  T0.""U_InqStatus"" = 3
   GROUP BY  T0.""U_CardCode"", T1.""U_ItemName"", T1.""U_Quantity"", T1.""U_UoM"", T1.""U_RawDrawNo"", T1.""U_FinalDrawNo"", T0.""DocEntry"", T0.""U_InqStatus"", T0.""U_InqNo""
   ORDER BY T0.""DocEntry"" ";

    $SQL_EXISTING_CALCULATIONS = "SELECT DISTINCT ""DocEntry"", ""U_ZofLineNum"", ""U_ZofNo"" FROM ""@CT_KOF_N"" WHERE IFNULL(""U_ZofNo"",0) IN ({0})";
    $SQL_EXISTING_OFFERS = "SELECT DISTINCT ""DocEntry"", ""U_ZOFno"" FROM OQUT WHERE ""U_ZOFno""  IN ({0});";

    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
    VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),'{0}','{1}','{2}','{3}',CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'KalkulacjaOferta.ps1','F')";

    #endregion 

    $code = $Company.Connected
    if ($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'

        $recordSetCalculations = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetCalculations.DoQuery($SQL_CALCULATIONS);
    
        $recordSetOffers = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetOffers.DoQuery($SQLQUERY_OFFERS);

        $recordSetLog = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")

        #region calculation
        $ppPositionsCount = $recordSetCalculations.RecordCount
        $msg = [string]::format('Pozycji do dodania: {0}', $ppPositionsCount)
        Write-Host -BackgroundColor Blue $msg

        $prevKey = '_';
        $dictionary = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[psobject]]'
        $dictExistingCalculations = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,string]]'
        $dictExistingOffers = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]'
        $dictionaryUpdateZof = New-Object 'System.Collections.Generic.Dictionary[string,string]'

        Write-Host 'Przygotowywanie danych o kalkulacjach'
    
        while (!$recordSetCalculations.EoF) {
            $DocEntry = $recordSetCalculations.Fields.Item('DocEntry').Value;
            $CardCode = $recordSetCalculations.Fields.Item('U_CardCode').Value;
            $CardName = $recordSetCalculations.Fields.Item('U_CardName').Value;
            $InqNo = $recordSetCalculations.Fields.Item('U_InqNo').Value;
            $LineId = $recordSetCalculations.Fields.Item('LineId').Value;
            $RawDrawNo = $recordSetCalculations.Fields.Item('U_RawDrawNo').Value;
            $FinalDrawNo = $recordSetCalculations.Fields.Item('U_FinalDrawNo').Value;
            $Stage = $recordSetCalculations.Fields.Item('U_Stage').Value;
            $Process = $recordSetCalculations.Fields.Item('U_Process').Value;
            $Line = $recordSetCalculations.Fields.Item('U_Line').Value;
            $Lack = $recordSetCalculations.Fields.Item('U_Lack').Value;
            $Size = $recordSetCalculations.Fields.Item('U_Size').Value;
            $Area = $recordSetCalculations.Fields.Item('U_Area').Value;
            $DirMatZl = $recordSetCalculations.Fields.Item('U_DirMatZl').Value;
            $DirMatKg = $recordSetCalculations.Fields.Item('U_DirMatKg').Value;
            $OthMat = $recordSetCalculations.Fields.Item('U_OthMat').Value;
            $Volume = $recordSetCalculations.Fields.Item('U_Volume').Value;
            $OperTime = $recordSetCalculations.Fields.Item('U_OperTime').Value;
            $MaskTime = $recordSetCalculations.Fields.Item('U_MaskTime').Value;            
            $EmpPrice = $recordSetCalculations.Fields.Item('U_EmpPrice').Value;
            $EmpEffic = $recordSetCalculations.Fields.Item('U_EmpEffic').Value;
            $PrcMultiple = $recordSetCalculations.Fields.Item('U_PrcMultiple').Value;
            $QtyScale = $recordSetCalculations.Fields.Item('U_QtyScale').Value;
            $HookPrice = $recordSetCalculations.Fields.Item('U_HookPrice').Value;
            $LineUse = $recordSetCalculations.Fields.Item('U_LineUse').Value;
            $LabMargin = $recordSetCalculations.Fields.Item('U_LabMargin').Value;
            $LogMargin = $recordSetCalculations.Fields.Item('U_LogMargin').Value;
            $StrMargin = $recordSetCalculations.Fields.Item('U_StrMargin').Value;
            $Margin = $recordSetCalculations.Fields.Item('U_Margin').Value;
            $F1Price = $recordSetCalculations.Fields.Item('U_F1Price').Value;
            $NatPriceSum = $recordSetCalculations.Fields.Item('U_NatPriceSum').Value;
            $ZnRate = $recordSetCalculations.Fields.Item('U_ZnRate').Value;
            $SpinYear = $recordSetCalculations.Fields.Item('U_SpinYear').Value;
            $Wlpk = $recordSetCalculations.Fields.Item('U_Wlpk').Value;
            $HangCost = $recordSetCalculations.Fields.Item('U_HangCost').Value;
            $SafeType = $recordSetCalculations.Fields.Item('U_SafeType').Value;
            $Vital = $recordSetCalculations.Fields.Item('U_Vital').Value;
            $HangQty = $recordSetCalculations.Fields.Item('U_HangQty').Value;
            $HangSpin = $recordSetCalculations.Fields.Item('U_HangSpin').Value;
            $ProdTime = $recordSetCalculations.Fields.Item('U_ProdTime').Value;
            $DayQty = $recordSetCalculations.Fields.Item('U_DayQty').Value;
            $HangNeed = $recordSetCalculations.Fields.Item('U_HangNeed').Value;
            $AddInsMargin = $recordSetCalculations.Fields.Item('U_AddInsMargin').Value;
            $Task = $recordSetCalculations.Fields.Item('Task').Value;


            $key = '' + $DocEntry + '_' + $RawDrawNo


            if ($key -ne $prevKey) {
                if ($prevKey -ne '_') {
                    $dictionary.Add($prevKey, $lines);
                }
                $lines = New-Object 'System.Collections.Generic.List[psobject]'

            }

            $line = [psobject]@{
                DocEntry     = $DocEntry;
                CardCode     = $CardCode;
                CardName     = $CardName;
                InqNo        = $InqNo
                LineId       = $LineId;
                RawDrawNo    = $RawDrawNo;
                FinalDrawNo  = $FinalDrawNo;
                Stage        = $Stage;
                Process      = $Process;
                Line         = $Line;
                Lack         = $Lack;
                Size         = $Size;
                Area         = $Area;
                DirMatZl     = $DirMatZl;
                DirMatKg     = $DirMatKg;
                OthMat       = $OthMat;
                Volume       = $Volume;
                OperTime     = $OperTime;
                MaskTime     = $MaskTime;
                EmpPrice     = $EmpPrice;
                EmpEffic     = $EmpEffic;
                PrcMultiple  = $PrcMultiple;
                QtyScale     = $QtyScale;
                HookPrice    = $HookPrice;
                LineUse      = $LineUse;
                LabMargin    = $LabMargin;
                LogMargin    = $LogMargin;
                StrMargin    = $StrMargin;
                Margin       = $Margin;
                F1Price      = $F1Price;
                NatPriceSum  = $NatPriceSum;
                ZnRate       = $ZnRate;
                SpinYear     = $SpinYear;
                Wlpk         = $Wlpk;
                HangCost     = $HangCost;
                SafeType     = $SafeType;
                Vital        = $Vital;
                HangQty      = $HangQty;
                HangSpin     = $HangSpin;
                ProdTime     = $ProdTime;
                DayQty       = $DayQty;
                HangNeed     = $HangNeed;
                AddInsMargin = $AddInsMargin;
                Task         = $Task;
            }
             
            $lines.Add($line); 
            $prevKey = $key;
            $recordSetCalculations.MoveNext();
        }
        
        if ($recordSetCalculations.RecordCount -gt 0) {
            $dictionary.Add($prevKey, $lines);
        }


        #endregion
   
        #region offer
        $ppPositionsCount = $recordSetOffers.RecordCount
        $msg = [string]::format('Pozycji do dodania: {0}', $ppPositionsCount)
        Write-Host -BackgroundColor Blue $msg

        $prevKey = '-1';
        $dictionaryOffers = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[psobject]]'

        Write-Host 'Przygotowywanie danych o ofertach'
        while (!$recordSetOffers.EoF) {
            $CardCode = $recordSetOffers.Fields.Item('CardCode').Value;
            $DocDate = $recordSetOffers.Fields.Item('DocDate').Value;
            $InqNo = $recordSetOffers.Fields.Item('U_InqNo').Value;
            $TaxDate = $recordSetOffers.Fields.Item('TaxDate').Value;
            $ItemCode = $recordSetOffers.Fields.Item('ItemCode').Value;
            $Dscription = $recordSetOffers.Fields.Item('Dscription').Value;
            $Quantity = $recordSetOffers.Fields.Item('Quantity').Value;
            $unitMsr = $recordSetOffers.Fields.Item('unitMsr').Value;
            $DrawRawNo = $recordSetOffers.Fields.Item('DrawRawNo').Value;
            $DrawFinalNo = $recordSetOffers.Fields.Item('DrawFinalNo').Value;
            $U_ZOFno = $recordSetOffers.Fields.Item('U_ZOFno').Value;
            $Task = $recordSetOffers.Fields.Item('Task').Value;
            $WhsCode = 'GW';
            $BPLId = $recordSetOffers.Fields.Item('Branch').Value;

            $key = $U_ZOFno


            if ($key -ne $prevKey) {
                if ($prevKey -ne -1) {
                    $dictionaryOffers.Add($prevKey, $linesOffers);
                }
                $linesOffers = New-Object 'System.Collections.Generic.List[psobject]'

            }

            $lineOffers = [psobject]@{
                CardCode    = $CardCode;
                DocDate     = $DocDate;
                TaxDate     = $TaxDate;
                ItemCode    = $ItemCode;
                InqNo       = $InqNo;
                Dscription  = $Dscription;
                Quantity    = $Quantity;
                unitMsr     = $unitMsr;
                DrawRawNo   = $DrawRawNo;
                DrawFinalNo = $DrawFinalNo;
                U_ZOFno     = $U_ZOFno;
                WhsCode     = $WhsCode;
                BPLId      = $BPLId;
                Task        = $Task;
            }
             
            $linesOffers.Add($lineOffers); 
            $prevKey = $key;
            $recordSetOffers.MoveNext();
        }
        
        if ($recordSetOffers.RecordCount -gt 0) { 
            $dictionaryOffers.Add($prevKey, $linesOffers);
        }
        #endregion

        #region existing documents
        
        $sql_param_zof_in = "";

        $countLines = $dictionary.Count + $dictionaryOffers.Count
        if ($countLines -gt 0){
            $k = 0;
            foreach ($key in $dictionary.Keys) {
                $tempDocEntry = $dictionary[$key][0].DocEntry;
                if ($k -eq $countLines - 1 ) {
                    $sql_param_zof_in +=  "'" + [string] $tempDocEntry + "'";
                }
                else {
                    $sql_param_zof_in += "'" + [string] $tempDocEntry + "',";
                }
                $k++;
            }
            foreach ($key in $dictionaryOffers.Keys) {
                if ($k -eq $countLines - 1 ) {
                    $sql_param_zof_in += "'" + [string] $key + "'";
                }
                else {
                    $sql_param_zof_in += "'" + [string] $key + "',";
                }
                $k++;
            }

            
            $recordSetExistingCalculations = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            $queryExistingCalculations = [string]::Format($SQL_EXISTING_CALCULATIONS, $sql_param_zof_in);
            $recordSetExistingCalculations.DoQuery($queryExistingCalculations);

            $recordSetExistingOffers = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
            $queryExistingOffers = [string]::Format($SQL_EXISTING_OFFERS, $sql_param_zof_in);
            $recordSetExistingOffers.DoQuery($queryExistingOffers);

            

            while (!$recordSetExistingCalculations.EoF) {
                $DocEntry = $recordSetExistingCalculations.Fields.Item('DocEntry').Value;
                $U_ZofLineNum = $recordSetExistingCalculations.Fields.Item('U_ZofLineNum').Value;
                $U_ZofNo = $recordSetExistingCalculations.Fields.Item('U_ZofNo').Value;
                
                if ($dictExistingCalculations.ContainsKey($U_ZOFno)) {
                    $existingCalculationsLines = $dictExistingCalculations[$U_ZOFno];
                }
                else {
                    $existingCalculationsLines = New-Object 'System.Collections.Generic.Dictionary[string,string]'
                    $dictExistingCalculations.Add($U_ZOFno,$existingCalculationsLines);
                }

                
                $existingCalculationsLines.Add($U_ZofLineNum, $DocEntry);
                $recordSetExistingCalculations.MoveNext();
            }

            while (!$recordSetExistingOffers.EoF) {
                $DocEntry = $recordSetExistingOffers.Fields.Item('DocEntry').Value;
                $U_ZOFno = $recordSetExistingOffers.Fields.Item('U_ZOFno').Value;
                
                if ($dictExistingOffers.ContainsKey($U_ZOFno)) {
                    $existingOffersLines = $dictExistingOffers[$U_ZOFno];
                }
                else {
                    $existingOffersLines = New-Object 'System.Collections.Generic.List[string]'
                    $dictExistingOffers.Add($U_ZOFno,$existingOffersLines);
                }

                $existingOffersLines.Add($DocEntry);
                $recordSetExistingOffers.MoveNext();
            }
        }
    
        
        #
   
        try {

            #region calculation documents
            $cs = $Company.GetCompanyService();
            $calculationDocEntryList = New-Object 'System.Collections.Generic.List[string]';
            #Dodanie kalkulacji
            Write-Host 'Dodanie / aktualizacja kalkulacji'
            foreach ($key in $dictionary.Keys) {
                try {

                    $lines = $dictionary[$key];
                    $firstLine = $lines[0]
                    $Task = $firstLine.Task;  
                    $ZofDocEntry = $firstLine.DocEntry;  
                    $LineId = $firstLine.LineId;  

                    $gs = $cs.GetGeneralService($CALCULATION_UDO_CODE);
                

                    if ($Task -eq 'U') {
                        $generalParams = $gs.GetDataInterface([SAPbobsCOM.GeneralServiceDataInterfaces]::gsGeneralDataParams)

                        $dictExistingCalculationsLines = $dictExistingCalculations[$ZofDocEntry];
                        $calculationDocEntry = $dictExistingCalculationsLines[$LineId];

                        $generalParams.SetProperty('DocEntry', $calculationDocEntry);
                        $calculation = $gs.GetByParams($generalParams);
                    }
                    else {
                        $calculation = $gs.GetDataInterface([SAPbobsCOM.GeneralServiceDataInterfaces]::gsGeneralData);
                    }
                                   
            
                    $calculation.SetProperty('U_ZofNo', $firstLine.DocEntry);
                    $calculation.SetProperty('U_ZofLineNum', $LineId);
                    $calculation.SetProperty('U_RawDrawNo', $firstLine.RawDrawNo);
                    $calculation.SetProperty('U_FinalDrawNo', $firstLine.FinalDrawNo);
                    $calculation.SetProperty('U_CardCode', $firstLine.CardCode);
                    $calculation.SetProperty('U_CardName', $firstLine.CardName);
                    $calculation.SetProperty('U_InqNo', $firstLine.InqNo);
            
                    $processLines = $calculation.Child($CALCULATION_PROCESS_LINES);
                    $toolsLines = $calculation.Child($CALCULATION_TOOLS_LINES);

                    if ($Task -eq 'U') {
                        $countProcessLines = $processLines.Count;
                        for ($index = $countProcessLines - 1; $index -ge 0; $index--) {
                            $processLines.Remove($index);
                        }
                    }

                    if ($Task -eq 'U') {
                        $countToolsLines = $toolsLines.Count;
                        for ($index = $countToolsLines - 1; $index -ge 0; $index--) {
                            $toolsLines.Remove($index);
                        }
                    }

                    $index = 0;
                    foreach ($line in $lines) {

                        $x = $processLines.Add();
                        $x = $toolsLines.Add();
                
                        $processLine = $processLines.Item($index);
                        $toolsLine = $toolsLines.Item($index);

                        $processLine.SetProperty('U_Stage', $line.Stage);
                        $processLine.SetProperty('U_Process', $line.Process);
                        $processLine.SetProperty('U_Line', $line.Line);
                        $processLine.SetProperty('U_Lack', $line.Lack);
                        $processLine.SetProperty('U_Size', $line.Size);
                        $processLine.SetProperty('U_Area', $line.Area);
                        $processLine.SetProperty('U_DirMatZl', $line.DirMatZl);
                        $processLine.SetProperty('U_DirMatKg', $line.DirMatKg);
                        $processLine.SetProperty('U_OthMat', $line.OthMat);
                        $processLine.SetProperty('U_Volume', $line.Volume);
                        $processLine.SetProperty('U_OperTime', $line.OperTime);
                        $processLine.SetProperty('U_MaskTime', $line.MaskTime);
                        $processLine.SetProperty('U_EmpPrice', $line.EmpPrice);
                        $processLine.SetProperty('U_EmpEffic', $line.EmpEffic);
                        $processLine.SetProperty('U_PrcMultiple', $line.PrcMultiple);
                        $processLine.SetProperty('U_QtyScale', $line.QtyScale);
                        $processLine.SetProperty('U_HookPrice', $line.HookPrice);
                        $processLine.SetProperty('U_LineUse', $line.LineUse);
                        $processLine.SetProperty('U_LabMargin', $line.LabMargin);
                        $processLine.SetProperty('U_LogMargin', $line.LogMargin);
                        $processLine.SetProperty('U_StrMargin', $line.StrMargin);
                        $processLine.SetProperty('U_Margin', $line.Margin);
                        $processLine.SetProperty('U_F1Price', $line.F1Price);
                        $processLine.SetProperty('U_NatPriceSum', $line.NatPriceSum);
                        $processLine.SetProperty('U_ZnRate', $line.ZnRate);
                        $processLine.SetProperty('U_SpinYear', $line.SpinYear);
                        $processLine.SetProperty('U_Wlpk', $line.Wlpk);
                        $processLine.SetProperty('U_AddPrcCost', 0);
                        $processLine.SetProperty('U_RepairCost', 0);
                        $processLine.SetProperty('U_PaintCost', 0);

                        $toolsLine.SetProperty('U_Stage', $line.Stage);
                        $toolsLine.SetProperty('U_Process', $line.Process);
                        $toolsLine.SetProperty('U_HangCost', $line.HangCost);
                        $toolsLine.SetProperty('U_SafeType', $line.SafeType);
                        $toolsLine.SetProperty('U_Vital', $line.Vital);
                        $toolsLine.SetProperty('U_HangQty', $line.HangQty);
                        $toolsLine.SetProperty('U_HangSpin', $line.HangSpin);
                        $toolsLine.SetProperty('U_ProdTime', $line.ProdTime);
                        $toolsLine.SetProperty('U_DayQty', $line.DayQty);
                        $toolsLine.SetProperty('U_HangNeed', $line.HangNeed);
                        $toolsLine.SetProperty('U_AddInsMargin', $line.AddInsMargin);
                        $toolsLine.SetProperty('U_SafeValue', 0);
                        $toolsLine.SetProperty('U_SafeCost', 0);

                        $index++;
                    }
            
                    if ($Task -eq 'U') {
                        $x = $gs.Update($calculation); 
                        setStatus $dictionaryUpdateZof $ZofDocEntry '2'
                        $calculationDocEntryList.Add($calculationDocEntry);
                    }
                    else {
                        $newCalculation = $gs.Add($calculation);
                        $calculationDocEntry = $newCalculation.GetProperty('DocEntry');
                    
                        $calculationDocEntryList.Add($calculationDocEntry);
                    }
                
                     
                    #$calculation.ToXMLFile("c:\temp\calc.xml");
                    
                    
                }
                Catch {
                    setStatus $dictionaryUpdateZof $ZofDocEntry '-1'
                    $err = $_.Exception.Message;
                    $actionDescription = 'dodana';
                    if ($Task -eq 'U') {
                        
                        $actionDescription = 'zaktualizowana';
                        $keyName = 'calculationDocEntry';
                        $keyValue = $calculationDocEntry;
                    }
                    else {
                        $keyName = 'ZofDocEntry';
                        $keyValue = $ZofDocEntry;

                    }

                    $ms = [string]::Format("Kalkulacja nie zosta³a {0}:{1}`n`nSzczegó³y: {2}", $actionDescription, $key, $err); 
                    
                    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                    $logQuery = [string]::Format($SQL_INSERT_LOG, $CALCULATION_UDO_CODE, $keyName, $keyValue, $ms.Replace("'","''"));
                    $recordSetLog.DoQuery($logQuery);

                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    continue;
                }
 
            }

            #endregion

            #region offers documents
        
            #Dodanie/aktualizacja ofert
            $offersDocEntryList = New-Object 'System.Collections.Generic.List[string]';
            Write-Host 'Dodanie/aktualizacja ofert'
            foreach ($key in $dictionaryOffers.Keys) {
                try {
                    $quotation = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oQuotations);

                    $lines = $dictionaryOffers[$key];
                    $firstLine = $lines[0]
                    $Task = $firstLine.Task;
                    $U_ZOFno = $firstLine.U_ZOFno;
                    $U_InqNo = $firstLine.InqNo;
                    if ($Task -eq 'U') {
                        $OfferDocEntry = [int] $dictExistingOffers[$U_ZOFno][0]
                        $quotation.GetByKey($OfferDocEntry);
                    }
                    else {
                        $quotation.CardCode = $firstLine.CardCode;
                        $quotation.DocDate = $firstLine.DocDate;
                        $quotation.TaxDate = $firstLine.TaxDate;
                        $quotation.UserFields.Fields.Item('U_ZOFno').Value = $U_ZOFno;
                        $quotation.UserFields.Fields.Item('U_InqNo').Value = [string] $U_InqNo;
                        $quotation.BPL_IDAssignedToInvoice = [string] $firstLine.BPLId;
                    }

                    

                    $items = $quotation.Lines;
                    
                    if ($Task -eq 'U') {
                        $countOfferLines = $items.Count;
                        for ($index = $countOfferLines - 1; $index -ge 0; $index--) {
                            $items.SetCurrentLine($index);
                            $items.Delete();
                        }
                    }


                    foreach ($line in $lines) {
                       # $items.SetCurrentLine($items.Count - 1);
                        $items.ItemCode = $line.ItemCode;
                        $items.WarehouseCode = $line.WhsCode;
                        $items.ItemDescription = $line.Dscription;
                        $items.Quantity = $line.Quantity; 
                        $items.MeasureUnit = $line.unitMsr;
                        $items.UserFields.Fields.Item('U_DrawRawNo').Value = [string]$line.DrawRawNo;
                        $items.UserFields.Fields.Item('U_DrawFinalNo').Value = [string]$line.DrawFinalNo;
                        $items.Add();
                    }
            
                    if ($Task -eq 'U') {
                        $message = $quotation.Update();
                        setStatus $dictionaryUpdateZof $U_ZOFno '2'
                    }
                    else {
                        $message = $quotation.Add();
                    }

                    
                    if (($message -lt 0) -and ($message -ne -1116)) {
                        setStatus $dictionaryUpdateZof $U_ZOFno '-1'
                        $actionDescription = 'dodana';
                        
                        if ($Task -eq 'U') {
                            $actionDescription = 'zaktualizowana';
                            $keyName = 'offerDocEntry';
                            $keyValue = $OfferDocEntry;
                        }
                        else {
                            $keyName = 'ZofDocEntry';
                            $keyValue = $ZofDocEntry;
                        }

                        $err = $Company.GetLastErrorDescription()
                        $ms = [string]::Format("Oferta nie zosta³a {0} dla ZOFNo {1}`n`nSzczegó³y: {2}", $actionDescription , $firstLine.U_ZOFno, $err); 
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms

                        # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                        $logQuery = [string]::Format($SQL_INSERT_LOG, '23', $keyName, $keyValue, $ms.Replace("'","''"));
                        $recordSetLog.DoQuery($logQuery);
                        continue;
                    } else {
                        if ($Task -eq 'A') {
                            $OfferDocEntry = $Company.GetNewObjectKey();
                        }
                        $offersDocEntryList.Add($OfferDocEntry);
                    }
                
                }
                Catch {
                    setStatus $dictionaryUpdateZof $U_ZOFno '-1'
                    $actionDescription = 'dodana';
                    if ($Task -eq 'U') {
                        $actionDescription = 'zaktualizowana';
                        $keyName = 'offerDocEntry';
                        $keyValue = $OfferDocEntry;
                    }
                    else {
                        $keyName = 'ZofDocEntry';
                        $keyValue = $ZofDocEntry;
                    }

                    $err = $_.Exception.Message;
                    $ms = [string]::Format("Oferta nie zosta³a {0} dla ZOFNo {1}`n`nSzczegó³y: {2}", $actionDescription, $firstLine.U_ZOFno, $err); 
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
                    $logQuery = [string]::Format($SQL_INSERT_LOG, '23', $keyName, $keyValue, $ms.Replace("'","''"));
                    $recordSetLog.DoQuery($logQuery);

                    continue;
                } 
                #endregion
            }

        
            updateZOF $pfcCompany $dictionaryUpdateZof
            foreach($calculationDocEntry in $calculationDocEntryList){
                try {
                    $gs = $cs.GetGeneralService($CALCULATION_UDO_CODE);
       
                    $generalParams = $gs.GetDataInterface([SAPbobsCOM.GeneralServiceDataInterfaces]::gsGeneralDataParams)
       
                    $generalParams.SetProperty('DocEntry', $calculationDocEntry);
                    $calculation = $gs.GetByParams($generalParams);
                    $gs.Update($calculation);
                } catch {
                    $err = $_.Exception.Message;
                    $ms = [string]::Format("B³¹d podczas dodatkowej aktualizacji kalkulacji DocEntry: {0}, Szczegó³y: {1}", $calculationDocEntry, $err); 
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                }
            }
            foreach($OfferDocEntry in $offersDocEntryList){
                try {
                    $quotation = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::oQuotations);
                    $quotation.GetByKey($OfferDocEntry);
                    $quotation.Update();
                } catch {
                    $err = $_.Exception.Message;
                    $ms = [string]::Format("B³¹d podczas dodatkowej aktualizacji oferty DocEntry: {0}, Szczegó³y: {1}", $OfferDocEntry, $err); 
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                }
            }

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