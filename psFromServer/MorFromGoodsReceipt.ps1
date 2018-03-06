function calculateShift($currentDate){
    $hour = $currentDate.Hour
    if($hour -lt 6)
    {
        return 3;
    } 
    elseif($hour -lt 14) 
    {
        return 1;
    } 
    elseif($hour -lt 22)
    {
        return 2;
    } 
    else
    {
        return 3
    }
    
}

function CreateMors($pfcCompany){

    $SQLQUERY_ITEMS_LIST = "select DL.""DocEntry"",D.""DocNum"",B.""U_ItemCode"", IFNULL(DL.""U_Revision"",B.""U_Revision"") AS ""Revision"", DL.""LineNum"", DL.""InvQty"" AS ""qty"", DL.""U_Technology"" 
        from IGN1 DL inner join OIGN D ON D.""DocEntry"" = DL.""DocEntry"" 
        inner join ""@CT_PF_BOM1"" BL ON DL.""ItemCode"" = BL.""U_ItemCode""
        inner join ""@CT_PF_OBOM"" B ON BL.""Code"" = B.""Code""
        
        WHERE DL.""U_Niezaplanowane"" = 'Y' ORDER BY DL.""DocEntry""";

    $SQLQUERY_MOR_DETAILS = "SELECT * FROM ""CT_LiniaPos""(@ItemCode,@Revision,@Iteration)";

    $SQLQUERY_UPDATE_STATUS = "UPDATE IGN1 SET ""U_Niezaplanowane"" = @Status WHERE ""DocEntry"" = @DocEntry AND ""LineNum"" = @LineNum";

    $SQLQUERY_CREATE_SSTU = "Call CreateSSTU_FROM_PW (@DocEntry,@LineNum,@MorEntry)";

    # {0} = U_Object, {1} = U_Key_Name, {2} = U_Key_Value, {3} = Remarks
    $SQL_INSERT_LOG = "INSERT INTO ""@LOG_POWERSHELL"" (""Code"",""Name"",""U_Object"",""U_Key_Name"",""U_Key_Value"",""U_Remarks"",""U_Date"",""U_Time"",""U_Script_Name"",""U_Status"")
        VALUES (SUBSTR(SYSUUID,0,30), SUBSTR(SYSUUID,0,30),@Object,@Key_Name,@Key_Value,@Remarks,CURRENT_DATE, CAST(CONCAT(HOUR(CURRENT_TIME),MINUTE(CURRENT_TIME)) AS int), 'MorFromGoodsReceipt.ps1','F')";

      
    
    $code = $pfcCompany.IsConnected
    if($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'

        #Query
        $queryManagerLog= New-Object CompuTec.Core.DI.Database.QueryManager
        $queryManagerLog.CommandText = $SQL_INSERT_LOG;
        $queryManagerCSSTU= New-Object CompuTec.Core.DI.Database.QueryManager
        $queryManagerCSSTU.CommandText = $SQLQUERY_CREATE_SSTU
        $queryManagerUpdate = New-Object CompuTec.Core.DI.Database.QueryManager
        $queryManagerUpdate.CommandText=$SQLQUERY_UPDATE_STATUS
        $queryManagerDetails = New-Object CompuTec.Core.DI.Database.QueryManager
        $queryManagerDetails.CommandText=$SQLQUERY_MOR_DETAILS
        $queryManager= New-Object CompuTec.Core.DI.Database.QueryManager
        $queryManager.CommandText=$SQLQUERY_ITEMS_LIST
        $rs=$queryManager.Execute($pfcCompany.Token);  
        $ppPositionsCount = $rs.RecordCount
        if($ppPositionsCount -gt 0){
            $msg = [string]::format('positions to add: {0}',$ppPositionsCount)
            Write-Host -BackgroundColor Blue $msg

        
        
            $createMorlist = New-Object 'System.Collections.Generic.List[psobject]'
            Write-Host 'Przygotowywanie danych o pozycjach'
            while(!$rs.EoF){
                $docEntry = $rs.Fields.Item('DocEntry').Value;
                $docNum = $rs.Fields.Item('DocNum').Value;
                $itemCode = $rs.Fields.Item('U_ItemCode').Value;
                $lineNum = $rs.Fields.Item('LineNum').Value;
                $qty = $rs.Fields.Item('qty').Value;
                $revision = $rs.Fields.Item('Revision').Value;
                $technology = $rs.Fields.Item('U_Technology').Value;

                $line = [psobject]@{
                    docEntry = $docEntry
                    docNum = $docNum
                    itemCode = $itemCode
                    lineNum = $lineNum
                    qty=$qty
                    revision = $revision
                    technology = $technology
                 };

                $createMorlist.Add($line);

                $rs.MoveNext();
            }
        
        

            foreach($line in $createMorlist)
            {           
            
                try {
                    $status = 'P';
                    $docEntry = $line.docEntry;
                    $lineNum = $line.lineNum;
                    $itemCode = $line.itemCode;
                    $revision = $line.revision;
                    $qty = $line.qty;
                    $technology = $line.technology;

                    $queryManagerUpdate.AddParameter("Status",$status);
                    $queryManagerUpdate.AddParameter("DocEntry",$docEntry);
                    $queryManagerUpdate.AddParameter("LineNum",$lineNum);
                    $dummy = $queryManagerUpdate.Execute($pfcCompany.Token);

                    $lineDetailsList = New-Object 'System.Collections.Generic.List[psobject]'
                    $currentDate = Get-Date
                    #collecting data
                    for($i=1;$i -le 10;$i++)
                    {
                        $queryManagerDetails.ClearParameters();
                        $queryManagerDetails.AddParameter("ItemCode",$itemCode);
                        $queryManagerDetails.AddParameter("Revision",$revision);
                        $queryManagerDetails.AddParameter("Iteration",$i);
                        $rsDetails = $queryManagerDetails.Execute($pfcCompany.Token);
                    
                        if($rsDetails.RecordCount -eq 0){
                            break;
                        }

                        $linia = $rsDetails.Fields.Item('U_Linia').Value;
                        $ilNaZawieszcze = $rsDetails.Fields.Item('U_IlNaZawieszcze').Value;
                        $ilNaPodzialce = $rsDetails.Fields.Item('U_IlNaPodzialce').Value;
                        $sumaPodzialek = $qty / $ilNaPodzialce;
                        $data = $currentDate.ToString("yyyy-MM-dd");
                        $zmiana = calculateShift($currentDate);

                        $details = [psobject]@{
                            linia = $linia
                            sumaPodzialek = $sumaPodzialek
                            ilNaZawieszcze = $ilNaZawieszcze
                            ilNaPodzialce = $ilNaPodzialce
                            data = $data
                            zmiana = $zmiana
                            ilosc = $qty
                         };


                        $lineDetailsList.Add($details)

                    }

                    #adding MOR
                    $mo = [CompuTec.ProcessForce.API.Core.Factory.UdoFactoryClass]::CreateDocument($pfcCompany.Token ,[CompuTec.ProcessForce.API.Core.ObjectTypes]::ManufacturingOrder);
                    $mo.U_ItemCode=$itemCode
                    $mo.U_Revision =$revision
                    $mo.U_RtgCode = $technology
                    $mo.U_RequiredDate= $data #'2017-04-01'
                    $mo.U_Quantity=$qty
                    $mo.CalculateManufacturingTimes($true);
                    $mo.U_Status=[CompuTec.ProcessForce.API.Enumerators.ManufacturingOrderStatus]::"Released";
                
                    $j = 1;
                    foreach($lineDetails in $lineDetailsList)
                    {

                        $udfNameLinia = 'U_Linia' + [string]$j;
                        $udfNameZmiana = 'U_Zmiana' + [string]$j;
                        $udfNameData = 'U_Data' + [string]$j;
                        $udfNameSumaPodzialek = 'U_SumaPodzialek' + [string]$j;
                        $udfNameIlNaZawieszce = 'U_IlNaZawieszce' + [string]$j;
                        $udfNameIlNaPodzialce = 'U_IlNaPodzialce' + [string]$j;
                        $udfNameIlosc = 'U_Ilosc' + [string]$j;

                        $mo.UDFItems.Item($udfNameLinia).Value = $lineDetails.linia
                        $mo.UDFItems.Item($udfNameZmiana).Value = $lineDetails.zmiana
                        $mo.UDFItems.Item($udfNameData).Value= [System.DateTime] $lineDetails.data
                        $mo.UDFItems.Item($udfNameSumaPodzialek).Value = $lineDetails.sumaPodzialek
                        $mo.UDFItems.Item($udfNameIlNaZawieszce).Value = $lineDetails.ilNaZawieszcze
                        $mo.UDFItems.Item($udfNameIlNaPodzialce).Value = $lineDetails.ilNaPodzialce

                        if($j -gt 1) {
                            $mo.UDFItems.Item($udfNameIlosc).Value = $lineDetails.ilosc
                        }

                        $j++;
                    }

                    $message = $mo.Add()
                    if($message -lt 0)
                    {
                        $err=$pfcCompany.GetLastErrorDescription()
                        $ms = [string]::Format("Zlecenie produkcyjne nie zostało dodane dla dokumentu PW: {0}, Linia: {1}`n`nSzczegóły: {2}",$line.docNum,$line.lineNum,$err); 
                        $Object = '59';
                        $KeyName = 'DocEntry';
                        $KeyValue = $line.docEntry;
                        $Remarks = $ms;

                    
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    
                        $queryManagerLog.AddParameter("Object",$Object);
                        $queryManagerLog.AddParameter("Key_Name",$KeyName);
                        $queryManagerLog.AddParameter("Key_Value",$KeyValue);
                        $queryManagerLog.AddParameter("Remarks",$Remarks);
                        $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                        $status = 'F';
                        $queryManagerUpdate.AddParameter("Status",$status);
                        $dummy = $queryManagerUpdate.Execute($pfcCompany.Token);
                        continue;
                    } 

            
                    $ms = [string]::Format("Zlecenie produkcyjne zostało poprawnie utworzone. Numer dokumentu: {0}",$mo.DocNum); 
                    Write-Host -BackgroundColor Green $ms
                    $status = 'S';
                    $queryManagerUpdate.AddParameter("Status",$status);
                    $dummy = $queryManagerUpdate.Execute($pfcCompany.Token);
                    $queryManagerCSSTU.AddParameter("DocEntry",$line.docEntry);
                    $queryManagerCSSTU.AddParameter("LineNum",$line.lineNum);
                    $queryManagerCSSTU.AddParameter("MorEntry",$mo.docEntry);
                    $dummy = $queryManagerCSSTU.Execute($pfcCompany.Token);
                } Catch {
                    $err=$_.Exception.Message;
                    $ms = [string]::Format("Zlecenie produkcyjne nie zostało dodane dla dokumentu PW: {0}, Linia: {1}`n`nSzczegóły: {2}",$line.docNum,$line.lineNum,$err);
                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                    $Object = '59';
                    $KeyName = 'DocEntry';
                    $KeyValue = $line.docEntry;
                    $Remarks = $ms;
                    $queryManagerLog.AddParameter("Object",$Object);
                    $queryManagerLog.AddParameter("Key_Name",$KeyName);
                    $queryManagerLog.AddParameter("Key_Value",$KeyValue);
                    $queryManagerLog.AddParameter("Remarks",$Remarks);
                    $dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                    $status = 'F';
                    $queryManagerUpdate.ClearParameters();
                    $queryManagerUpdate.AddParameter("Status",$status);
                    $queryManagerUpdate.AddParameter("DocEntry",$docEntry);
                    $queryManagerUpdate.AddParameter("LineNum",$lineNum);
                    $dummy = $queryManagerUpdate.Execute($pfcCompany.Token);
                    continue;
                }
            }
            Start-Sleep -Seconds 10
        } else 
        {
            $msg = [string]::format('Brak pozycji do wydania')
            Write-Host -BackgroundColor Blue $msg
            Start-Sleep -Seconds 10
        }
    }
    else
    {
        $msg = [string]::format("Bład połączenia.")
    }
}