# użycie biblioteki SAPbobsCOM.dll


#. C:\Computec\Powershell\ProcessOrderLine.ps1
#$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
 
#$isConnected= Connect -pfcCompany $pfcCompany
#$Company = $pfcCompany.SapCompany
#$Company = new-Object -ComObject SAPbobsCOM.Company
#$Company = $sapCompany
#$Company.Server = "172.16.0.54:30015"
#$Company.DbUserName = "SYSTEM"
#$Company.DbPassword = "Ep*4321#"
#$Company.CompanyDB = "TEST_20161130"
#$Company.LicenseServer = "172.16.0.53:40000"
#$Company.UserName = "rafald"
#$Company.Password = "1234"
#$Company.DbServerType = [SAPbobsCOM.BoDataServerTypes]::dst_HANADB
#test

function ZlecenieWysylki($Company){

    $lErrCode = 0
    $sErrMsg = ""
    $UDO_CODE = 'CT_ZW';
    $UDO_PROCESS_LINES = 'CT_ZW_POZ';

#region sql queries  
$SQL_ZW = "
WITH CTE AS (
SELECT DISTINCT 
 T2.""ItemCode"", T3.""WhsCode"", CASE WHEN SUM(T4.""OnHandQty"")-IFNULL(T3.""CommitQty"",0) > 0 THEN SUM(T4.""OnHandQty"")-IFNULL(T3.""CommitQty"",0) ELSE 0 END ""QtyOnHand""
FROM OBTN T2
INNER JOIN OBTQ T3 ON T2.""AbsEntry"" = T3.""MdAbsEntry"" 
INNER JOIN OBBQ T4 ON T2.""AbsEntry"" = T4.""SnBMDAbs"" AND T3.""WhsCode"" = T4.""WhsCode""
INNER JOIN OBIN T5 ON T4.""BinAbs"" = T5.""AbsEntry""
WHERE T5.""BinCode"" NOT LIKE '%IZO%' AND T5.""BinCode"" NOT LIKE '%BRAK%' 
GROUP BY T2.""ItemCode"", T3.""WhsCode"", IFNULL(T3.""CommitQty"",0)
)


SELECT
 T0.""DocEntry"",
 T0.""CardCode"" AS ""U_CardCode"",
 T0.""CardName"" AS ""U_CardName"",
 T0.""DocDueDate"" AS ""U_ShipDate"",
 T0.""Address2"" AS ""U_ShipToDesc"",
 T0.""DocNum"" AS ""U_SchedNo"",
 
 T1.""ItemCode"" || '_' || T1.""LineNum"" AS ""U_Position"",
 T1.""DocEntry"" AS ""U_DocEntryZS"",
 T1.""LineNum"" AS ""U_LineNumZS"",
 T2.""U_DrawNoFinal"" AS ""U_DrawNoFinal"",
 T1.""ItemCode"" AS ""U_ItemCode"",
 T1.""Dscription"" AS ""U_ItemName"",
 T1.""Quantity"" AS ""QtyOnPal"",
 CEILING((G0.""InvQty"" - G1.""U_QtySum"")/T1.""Quantity"") AS ""U_PalQty"",
 G0.""InvQty"" - G1.""U_QtySum"" AS ""U_QtySum"",
 CAST(T1.""Text"" AS NVARCHAR(10000)) AS ""U_Priority"",
 T1.""InvQty"" AS ""U_OpenQty"",
 IFNULL(G2.""QtyOnHand"",0) AS ""U_QtyOnHand""
 --SUM(T5.""OnHandQty""-IFNULL(T4.""CommitQty"",0)),
 --SUM(T1.""InvQty"") - SUM(IFNULL(T7.""U_QtySum"",0))
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0.""DocEntry"" = T1.""DocEntry""
 INNER JOIN OITM T2 ON T1.""ItemCode"" = T2.""ItemCode""
 LEFT OUTER JOIN ""@CT_ZW_POZ"" T7 ON T1.""DocEntry"" = T7.""U_DocEntryZS"" AND T1.""LineNum"" = T7.""U_LineNumZS""
 LEFT OUTER JOIN (SELECT
 					T0.""DocEntry"", T1.""LineNum"", SUM(T1.""InvQty"") AS ""InvQty""
 				  FROM ORDR T0
 					INNER JOIN RDR1 T1 ON T0.""DocEntry"" = T1.""DocEntry""
 					INNER JOIN OITM T2 ON T1.""ItemCode"" = T2.""ItemCode""
 				  GROUP BY T0.""DocEntry"", T1.""LineNum"") G0 ON T0.""DocEntry"" = G0.""DocEntry"" AND T1.""LineNum"" = G0.""LineNum""
 LEFT OUTER JOIN (SELECT
 					T0.""DocEntry"", T1.""LineNum"", SUM(IFNULL(T7.""U_QtySum"",0)) AS ""U_QtySum""
 				  FROM ORDR T0
 					INNER JOIN RDR1 T1 ON T0.""DocEntry"" = T1.""DocEntry""
 					INNER JOIN OITM T2 ON T1.""ItemCode"" = T2.""ItemCode""
 					LEFT OUTER JOIN ""@CT_ZW_POZ"" T7 ON T1.""DocEntry"" = T7.""U_DocEntryZS"" AND T1.""LineNum"" = T7.""U_LineNumZS""
 				  WHERE T0.""DocEntry"" || '_' || T1.""LineNum"" NOT IN (
 				  SELECT DISTINCT
					 T0.""BaseEntry"" || '_' || T0.""BaseLine""
					FROM DLN1 T0
					 INNER JOIN RDN1 T1 ON T0.""DocEntry"" = T1.""BaseEntry"" AND T0.""LineNum"" = T1.""BaseLine"" AND T0.""ObjType"" = T1.""BaseType""
					WHERE T0.""BaseType"" = 17)
 				  GROUP BY T0.""DocEntry"", T1.""LineNum"") G1 ON T0.""DocEntry"" = G1.""DocEntry"" AND T1.""LineNum"" = G1.""LineNum""
 LEFT OUTER JOIN (SELECT  
 					""ItemCode"", ""WhsCode"", SUM(""QtyOnHand"") AS ""QtyOnHand""
				  FROM CTE
				  GROUP BY ""ItemCode"", ""WhsCode""
				  ORDER BY ""ItemCode"") G2 ON T1.""ItemCode"" = G2.""ItemCode"" AND T1.""WhsCode"" = G2.""WhsCode""
 				  
WHERE --T0.""DocNum"" = 132

IFNULL(T0.""U_CreateSendOrder"",'N') = 'T' 

AND 
(T1.""DocEntry"" || '_' || T1.""LineNum"" NOT IN
(
SELECT DISTINCT
 G0.""OrderEntry"" || '_' || G0.""OrderLine""
FROM PKL1 G0
WHERE G0.""BaseObject"" = 17
AND G0.""OrderEntry"" || '_' || G0.""OrderLine"" NOT IN (
SELECT DISTINCT
 T0.""BaseEntry"" || '_' || T0.""BaseLine""
FROM DLN1 T0
 INNER JOIN RDN1 T1 ON T0.""DocEntry"" = T1.""BaseEntry"" AND T0.""LineNum"" = T1.""BaseLine"" AND T0.""ObjType"" = T1.""BaseType""
WHERE T0.""BaseType"" = 17)
) OR G0.""InvQty"" - G1.""U_QtySum"" > 0)

AND 
(T1.""DocEntry"" || '_' || T1.""LineNum"" NOT IN
(
SELECT DISTINCT
 IFNULL(G1.""U_DocEntryZS"",0) || '_' || IFNULL(G1.""U_LineNumZS"",0)
FROM ""@CT_ZW_POZ"" G1
WHERE IFNULL(G1.""U_DocEntryZS"",0) || '_' || IFNULL(G1.""U_LineNumZS"",0) NOT IN (
SELECT DISTINCT
 T0.""BaseEntry"" || '_' || T0.""BaseLine""
FROM DLN1 T0
 INNER JOIN RDN1 T1 ON T0.""DocEntry"" = T1.""BaseEntry"" AND T0.""LineNum"" = T1.""BaseLine"" AND T0.""ObjType"" = T1.""BaseType""
WHERE T0.""BaseType"" = 17)
)
OR G0.""InvQty"" - G1.""U_QtySum"" > 0)

AND T1.""LineStatus"" = 'O'

GROUP BY
T0.""DocEntry"",
 T0.""CardCode"",
 T0.""CardName"",
 T0.""DocDueDate"",
 T0.""Address2"",
 T0.""DocNum"",
 
 T1.""ItemCode"" || '_' || T1.""LineNum"",
 T1.""DocEntry"",
 T1.""LineNum"",
 T2.""U_DrawNoFinal"",
 T1.""ItemCode"",
 T1.""Dscription"",
 T1.""Quantity"",
 T1.""NumPerMsr"",
 CAST(T1.""Text"" AS NVARCHAR(10000)),
 G0.""InvQty"" - G1.""U_QtySum"",
 T1.""InvQty"",
 IFNULL(G2.""QtyOnHand"",0)
ORDER BY T0.""DocEntry"", T1.""LineNum""
 " ;

 #endregion 

     
    #$code = $Company.Connect()
    $code = $Company.Connected
    if($code -eq $true) {
    
        Write-Host -BackgroundColor Green 'Connection successful'

        $recordSetshipments = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]::"BoRecordset")
        $recordSetshipments.DoQuery($SQL_ZW);
 

        #region calculation
        $ppPositionsCount = $recordSetshipments.RecordCount
        $msg = [string]::format('Pozycji do dodania: {0}',$ppPositionsCount)
        Write-Host -BackgroundColor Blue $msg
        if($ppPositionsCount -gt 0){
            $prevKey = -1;
            $dictionary = New-Object 'System.Collections.Generic.Dictionary[int,System.Collections.Generic.List[psobject]]'

            Write-Host 'Przygotowywanie danych o zleceniach'
    
            while(!$recordSetshipments.EoF){
                $DocEntry = $recordSetShipments.Fields.Item('DocEntry').Value;
                $U_CardCode = $recordSetShipments.Fields.Item('U_CardCode').Value;
                $U_CardName = $recordSetShipments.Fields.Item('U_CardName').Value;
                $U_ShipDate = $recordSetShipments.Fields.Item('U_ShipDate').Value;
                $U_ShipToDesc = $recordSetShipments.Fields.Item('U_ShipToDesc').Value;
                $U_SchedNo = $recordSetShipments.Fields.Item('U_SchedNo').Value;
                $U_Position = $recordSetShipments.Fields.Item('U_Position').Value;
                $U_DocEntryZS = $recordSetShipments.Fields.Item('U_DocEntryZS').Value;
                $U_LineNumZS = $recordSetShipments.Fields.Item('U_LineNumZS').Value;
                $U_DrawNoFinal = $recordSetShipments.Fields.Item('U_DrawNoFinal').Value;
                $U_ItemCode = $recordSetShipments.Fields.Item('U_ItemCode').Value;
                $U_ItemName = $recordSetShipments.Fields.Item('U_ItemName').Value;
                $QtyOnPal = $recordSetShipments.Fields.Item('QtyOnPal').Value;
                $U_PalQty = $recordSetShipments.Fields.Item('U_PalQty').Value;
                $U_QtySum = $recordSetShipments.Fields.Item('U_QtySum').Value;
                $U_Priority = $recordSetShipments.Fields.Item('U_Priority').Value;
                $U_OpenQty = $recordSetShipments.Fields.Item('U_OpenQty').Value;
                $U_QtyOnHand = $recordSetShipments.Fields.Item('U_QtyOnHand').Value;



                $key =$DocEntry


                if($key -ne $prevKey) {
                    if($prevKey -ne -1){
                        $dictionary.Add($prevKey, $lines);
                    }
                    $lines = New-Object 'System.Collections.Generic.List[psobject]'

                }

                $line = [psobject]@{
                    DocEntry = $DocEntry;
                    U_CardCode = $U_CardCode;
                    U_CardName = $U_CardName;
                    U_ShipDate = $U_ShipDate;
                    U_ShipToDesc = $U_ShipToDesc;
                    U_SchedNo = $U_SchedNo;
                    U_Position = $U_Position;
                    U_DocEntryZS = $U_DocEntryZS;
                    U_LineNumZS = $U_LineNumZS;
                    U_DrawNoFinal = $U_DrawNoFinal;
                    U_ItemCode = $U_ItemCode;
                    U_ItemName = $U_ItemName;
                    QtyOnPal = $QtyOnPal;
                    U_PalQty = $U_PalQty;
                    U_QtySum = $U_QtySum;
                    U_Priority = $U_Priority;
                    U_OpenQty = $U_OpenQty;
                    U_QtyOnHand = $U_QtyOnHand;

                }
             
                $lines.Add($line); 
                $prevKey = $key;
                $recordSetshipments.MoveNext();
            }
        
        
            $dictionary.Add($prevKey, $lines);
            #endregion
   
   
            try {

                #region UDO documents
                $cs = $Company.GetCompanyService();

                #Dodanie udo
        
                foreach($key in $dictionary.Keys)
                {
                    if($key -ne -1){
                        Write-Host 'Dodanie zlecenia wysyłki'
                        try {
                            $gs = $cs.GetGeneralService($UDO_CODE);
                            try {
                                $udo_zw = $gs.GetDataInterface([SAPbobsCOM.GeneralServiceDataInterfaces]::gsGeneralData);
                            } finally {
                              #  Memory.ReleaseComObject($cs);
                              #  Memory.ReleaseComObject($gs);
                            } 

                            $lines = $dictionary[$key];
                            $firsLine = $lines[0]
            
                            $udo_zw.SetProperty('U_CardCode',$firsLine.U_CardCode);
                            $udo_zw.SetProperty('U_CardName',$firsLine.U_CardName);
                            $udo_zw.SetProperty('U_ShipDate',$firsLine.U_ShipDate);
                            $udo_zw.SetProperty('U_ShipToDesc',$firsLine.U_ShipToDesc);
                            $udo_zw.SetProperty('U_SchedNo',$firsLine.U_SchedNo);
            
                            $udoLines = $udo_zw.Child($UDO_PROCESS_LINES);

                            $index = 0;
                            foreach($line in $lines)
                            {
                                $x = $udoLines.Add();
                
                                $udoLine = $udoLines.Item($index);


                                $udoLine.SetProperty('U_Position',$line.U_Position);
                                $udoLine.SetProperty('U_DocEntryZS',$line.U_DocEntryZS);
                                $udoLine.SetProperty('U_LineNumZS',$line.U_LineNumZS);
                                $udoLine.SetProperty('U_DrawNoFinal',$line.U_DrawNoFinal);
                                $udoLine.SetProperty('U_ItemCode',$line.U_ItemCode);
                                $udoLine.SetProperty('U_ItemName',$line.U_ItemName);
                                $udoLine.SetProperty('U_QtyOnPal',$line.QtyOnPal);
                                $udoLine.SetProperty('U_PalQty',$line.U_PalQty);
                                $udoLine.SetProperty('U_QtySum',$line.U_QtySum);
                                $udoLine.SetProperty('U_Priority',$line.U_Priority);
                                $udoLine.SetProperty('U_OpenQty',$line.U_OpenQty);
                                $udoLine.SetProperty('U_QtyOnHand',$line.U_QtyOnHand);


                                $index++;
                            }
            

                            $x = $gs.Add($udo_zw);
                
                

                 
                         } Catch {
                    
                            $err=$_.Exception.Message;
                            $ms = [string]::Format("Zlecenie wysyłki nie zostało dodane:{0}`n`nSzczegóły: {1}",$key,$err); 
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                            continue;
                        } 
                    }
                }

                #endregion


            } Catch {
                $err=$_.Exception.Message;
                $ms = [string]::Format("Wystąpił błąd: {0}",$err); 
                Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                exit;
            }
            Start-Sleep -Seconds 5
        } else {
            Start-Sleep -Seconds 10
        }
    }
    else
    {
        $msg = [string]::format("Bład połączenia.")
        Write-Host -BackgroundColor Red -ForegroundColor White $msg
    }
}