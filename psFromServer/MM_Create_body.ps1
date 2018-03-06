
function MM_beetweenLocations($pfcCompany)
{
    $LogFileName = 'C:\Temp\MMCreateLog.txt';
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Wywołanie funkcji: '  >> $LogFileName
     $MainList = New-Object 'System.Collections.Generic.List[psobject]'
     $selet="select * from CT_PRODUKCJA_RzadaniePrzesunieciaGrouped order by ""U_DocEntry"", ""U_FromBinCode"" ,""U_ToBinCode"" ";
     $select ="select t0.*,t5.""DocEntry"" ""WTQENTRY"", tdrf.""DocEntry"" ""DrfEntry"" from CT_PRODUKCJA_RzadaniePrzesunieciaGrouped t0 
left outer join wtq1 t1 on cast(t0.""U_DocEntry"" as nvarchar(11))=t1.""U_DocEntry""and t0.""GNIAZDO""='N' and ""LineStatus""='O' and
						(
							(
							t0.""BUFOR"" ='N' and 
							t1.""U_FromBinCode""=t0.""U_FromBinCode"" and 
							t1.""U_ToBinCode""=t0.""U_ToBinCode""
							)
						or 
							(
								t0.""BUFOR"" ='Y' and 
								t1.""U_FromBinCode""=t0.""U_FromBinCode"" and 
								t1.""U_ToBinCode""=t0.""KWARANTANNA""
							)
						)
						left outer  join owtq t5 on t1.""DocEntry""=t5.""DocEntry"" and t5.""DocStatus""='O' and t5.""U_Dismiss"" <>'1'
left outer join (
select  t3.""U_DocEntry""   ""MorEntry"",t3.""U_FromBinCode"",t3.""U_ToBinCode"",t3.""DocEntry""
from  owtq t2  
inner join wtq1   t3 on t2.""DocEntry""=t3.""DocEntry""
where t2.""DocStatus""='O' and ""LineStatus"" ='O' ) tdrf on 

    tdrf.""MorEntry""=cast(t0.""U_DocEntry"" as nvarchar(11))and tdrf.""U_FromBinCode""=t0.""KWARANTANNA"" and 
								tdrf.""U_ToBinCode""=t0.""U_ToBinCode"" 
								
								where 
								
								t0.""Quantity"" >0         "
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Przed zapytaniami: '  >> $LogFileName
    $a= New-Object CompuTec.Core.DI.Database.QueryManager
    $a.CommandText=$select;
    $recordSetRwLines=$a.Execute($pfcCompany.Token);
   
   while(!$recordSetRwLines.EoF)
            {
             try{ 
                $Quantity = $recordSetRwLines.Fields.Item('Quantity').Value;
                $ItemCode = $recordSetRwLines.Fields.Item('ItemCode').Value;
                $FromBinCode = $recordSetRwLines.Fields.Item('U_FromBinCode').Value;
                $ToBinCode = $recordSetRwLines.Fields.Item('U_ToBinCode').Value;
                $MorDocEntry = $recordSetRwLines.Fields.Item('U_DocEntry').Value;
                $FromWhs = $recordSetRwLines.Fields.Item('FromWhsCode').Value;
                $ToWhs = $recordSetRwLines.Fields.Item('ToWhsCode').Value;
                $BUFOR = $recordSetRwLines.Fields.Item('BUFOR').Value;
                $FromBinAbs =$recordSetRwLines.Fields.Item('FromBinAbs').Value;
                $ToBinAbs =$recordSetRwLines.Fields.Item('ToBinAbs').Value;
                $GNIAZDO = $recordSetRwLines.Fields.Item('GNIAZDO').Value;
                $KWARANTANNABinAbs=$recordSetRwLines.Fields.Item('KWBINABS').Value;
                $KWARANTANNA=$recordSetRwLines.Fields.Item('KWARANTANNA').Value;
                $WtrEntry = $recordSetRwLines.Fields.Item('WTQENTRY').Value;
                $DrfEntry=$recordSetRwLines.Fields.Item('DrfEntry').Value;
                $SU_List=$recordSetRwLines.Fields.Item('Units').Value;
                $recordSetRwLines.MoveNext();
                if($GNIAZDO -eq 'Y')
                {
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Dodanie MM: '  >> $LogFileName
                    # robimy mmke 
                     $ST= $pfcCompany.CreateSapObject([SAPbobsCOM.BoObjectTypes]::oStockTransfer)
                     $ST.UserFields.Fields.Item("U_Guid").Value='2'
                     $ST.FromWarehouse=$FromWhs
                     $ST.ToWarehouse=$ToWhs
                     $lines=$ST.Lines;
                     $lines.ItemCode = $ItemCode
                     $lines.WarehouseCode = $ToWhs
                     $lines.FromWarehouseCode = $FromWhs
                     $lines.Quantity = $Quantity

                     $lines.UserFields.Fields.Item("U_LineNum").Value = 1;
                     $lines.UserFields.Fields.Item("U_DocEntry").Value = $MorDocEntry.ToString()
                     $lines.UserFields.Fields.Item("U_ItemType").Value = "IT";
                     $lines.UserFields.Fields.Item("U_Revision").Value = "code00"
                     $lines.UserFields.Fields.Item("U_FromBinCode").Value =  $FromBinCode
                     
                     if($BUFOR -eq 'Y')
                       {
                            $lines.UserFields.Fields.Item("U_ToBinCode").Value = $KWARANTANNA
                       }
                        else
                       {
                            $lines.UserFields.Fields.Item("U_ToBinCode").Value =$ToBinCode
                       }

                     $b= New-Object CompuTec.Core.DI.Database.QueryManager
                     $b.CommandText="select   ""U_Attribute3"", sum(""U_IloscSU"") ""U_IloscSU""  from ""@CT_WMS_OSTU"" where ""Code"" in (@Codes) group by ""U_Attribute3"""
                       $b.AddParameter("Codes",[CompuTec.Core.DI.Database.QueryManager]::GenerateSqlInStatment( $SU_List.ToString().Split(',')));
                     $btches=$b.Execute($pfcCompany.Token);
                     $dbatch=$lines.BatchNumbers;
                      $batchLN=0
                     while(!$btches.EoF)
                     {
                            $bqty= $btches.Fields.Item("U_IloscSU").Value;
                                    $lines.BatchNumbers.BatchNumber = $btches.Fields.Item("U_Attribute3").Value;
                                    #$lines.BatchNumbers.BaseLineNumber = $issue.Lines.LineNum
                                    $lines.BatchNumbers.Quantity = $bqty
                                    
                                    $lines.BatchNumbers.Add()
                                    

                                    $lines.BinAllocations.BinAbsEntry = $FromBinAbs
                                    $lines.BinAllocations.Quantity =$bqty
                                    $lines.BinAllocations.BaseLineNumber =  $lines.LineNum
                                    $lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN
                                    $lines.BinAllocations.BinActionType=[SAPbobsCOM.BinActionTypeEnum]::batFromWarehouse
                                    $lines.BinAllocations.Add()
                                    if($BUFOR -eq 'Y') 
                                    {
                                    $lines.BinAllocations.BinAbsEntry = $KWARANTANNABinAbs
                                    }else
                                    {
                                    $lines.BinAllocations.BinAbsEntry =  $ToBinAbs
                                    }

                                    $lines.BinAllocations.Quantity = $bqty
                                    $lines.BinAllocations.BaseLineNumber =  $lines.LineNum
                                    $lines.BinAllocations.BinActionType=[SAPbobsCOM.BinActionTypeEnum]::batToWarehouse
                                    $lines.BinAllocations.SerialAndBatchNumbersBaseLine = $batchLN
                                    $lines.BinAllocations.Add()
                                $btches.MoveNext();
                                   $batchLN++;
                     }
                     $LogDateTime = Get-Date
                     [string]$LogDateTime + ' Rozpoczęcie transakcji: '  >> $LogFileName
                        if(!$pfcCompany.InTransaction)
                                    {
                                        $pfcCompany.StartTransaction(); 
                                    }
                   $message = $ST.Add();
                   $LogDateTime = Get-Date
                   [string]$LogDateTime + ' Po dodaniu: '  >> $LogFileName
                   if($message -lt 0)
                        {
                            $err=$pfcCompany.GetLastErrorDescription()
                            $ms = [string]::Format(" [Gniazdo] Przesuniecie   nie zostało dodane `n`nSzczegóły: {0}`nSTUCode: {1} DocEntry{2}", $err,$SU_List, $MorDocEntry); 
                            $Object = 'CT_PF_PickOrder';
                            $KeyName = 'DocEntry';
                            $KeyValue = $pickOrder.DocEntry;
                            $Remarks = $ms;

                            #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                            Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                           if($pfcCompany.InTransaction){
                                $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                            }
                    
                            #$queryManagerLog.ClearParameters();
                            #$queryManagerLog.AddParameter("Object",$Object);
                            #$queryManagerLog.AddParameter("Key_Name",$KeyName);
                            #$queryManagerLog.AddParameter("Key_Value",$KeyValue);
                            #$queryManagerLog.AddParameter("Remarks",$Remarks);
                            #$dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                            continue;
                        }  
                  }
                  else #Gniazdo
                  {
                  #miedzy gniazdami żądanie
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Przygotowanie żądania przesunięcia: '  >> $LogFileName
                    $ST= $pfcCompany.CreateSapObject([SAPbobsCOM.BoObjectTypes]::oInventoryTransferRequest)
                        if($WtrEntry -gt 0)
                            {
                             $ST.GetByKey($WtrEntry);
                                $ST.Lines.SetCurrentLine(0)
                                $ST.Lines.Quantity+= $Quantity
                                if(!$pfcCompany.InTransaction)
                                    {
                                        $pfcCompany.StartTransaction(); 
                                    }
                                $LogDateTime = Get-Date
                                [string]$LogDateTime + ' Przed aktualizacją żądania przesunięcia: '  >> $LogFileName    
                                $message = $ST.Update();
                                $LogDateTime = Get-Date
                                [string]$LogDateTime + ' Po aktualizacji żądania przesunięcia: '  >> $LogFileName    
                             if($message -lt 0)
                                {
                                    $err=$pfcCompany.GetLastErrorDescription()
                                    $ms = [string]::Format(" [] Żądanie Przesuniecie   nie zostało zaktualizowane `n`nSzczegóły: {0}`nSTUCode: {1} DocEntry{2}",$WtrEntry,$err,$akcja.stuCodesLine); 
                                    $Object = 'MMR_Create';
                                    $KeyName = 'DocEntry';
                                    $KeyValue = $WtrEntry;
                                    $Remarks = $ms;

                                    #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                    if($pfcCompany.InTransaction)
                                    {
                                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                    }
                    
                                    #$queryManagerLog.ClearParameters();
                                    #$queryManagerLog.AddParameter("Object",$Object);
                                    #$queryManagerLog.AddParameter("Key_Name",$KeyName);
                                    #$queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                    #$queryManagerLog.AddParameter("Remarks",$Remarks);
                                    #$dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                    continue;
                                }
                           }else
                           {
                            $LogDateTime = Get-Date
                            [string]$LogDateTime + ' Przygotowanie żądania przesunięcia: '  >> $LogFileName
                            $ST= $pfcCompany.CreateSapObject([SAPbobsCOM.BoObjectTypes]::oInventoryTransferRequest)
                            $ST.FromWarehouse=$FromWhs
                             $ST.ToWarehouse=$ToWhs
                             $lines=$ST.Lines;
                             $lines.ItemCode = $ItemCode
                             $lines.WarehouseCode = $ToWhs
                             $lines.FromWarehouseCode = $FromWhs
                             $lines.Quantity = $Quantity

                             $lines.UserFields.Fields.Item("U_LineNum").Value = 1;
                             $lines.UserFields.Fields.Item("U_DocEntry").Value = $MorDocEntry.ToString()
                             $lines.UserFields.Fields.Item("U_ItemType").Value = "IT";
                             $lines.UserFields.Fields.Item("U_Revision").Value = "code00"
                             $lines.UserFields.Fields.Item("U_FromBinCode").Value =  $FromBinCode

                              if($BUFOR -eq "Y")
                             {
                                $lines.UserFields.Fields.Item("U_ToBinCode").Value =$KWARANTANNA
                             }else
                             {
                              $lines.UserFields.Fields.Item("U_ToBinCode").Value =$ToBinCode
                             }
                             if(!$pfcCompany.InTransaction)
                            {
                                $pfcCompany.StartTransaction(); 
                            }
                            $LogDateTime = Get-Date
                            [string]$LogDateTime + ' Przed dodaniem żądania przesunięcia: '  >> $LogFileName    
                            $message = $ST.Add();
                            $LogDateTime = Get-Date
                            [string]$LogDateTime + ' Po dodaniu żądania przesunięcia: '  >> $LogFileName    
                             if($message -lt 0)
                                {
                                    $err=$pfcCompany.GetLastErrorDescription()
                                    $ms = [string]::Format("Żądanie przesuniecie   nie zostało zaktualizowane `n`nSzczegóły: {0}`nSTUCode: {1} DocEntry{2}",$pickOrder.DocNum,$err,$akcja.stuCodesLine); 
                                    $Object = 'MM_Create_Draft';
                                    $KeyName = 'DocEntry';
                                    $KeyValue = $DrfEntry;
                                    $Remarks = $ms;

                                    #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                   if($pfcCompany.InTransaction){
                                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                    }
                    
                                    #$queryManagerLog.ClearParameters();
                                    #$queryManagerLog.AddParameter("Object",$Object);
                                    #$queryManagerLog.AddParameter("Key_Name",$KeyName);
                                    #$queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                    #$queryManagerLog.AddParameter("Remarks",$Remarks);
                                    #$dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                    continue;
                                }  

                           }
                                
                                  
                  }
                   
                        if($BUFOR -eq "Y")
                        {
                            $LogDateTime = Get-Date
                            [string]$LogDateTime + ' Przygotowanie dok.  przesunięcia z buf na maszyne: '  >> $LogFileName  
                            $ST= $pfcCompany.CreateSapObject([SAPbobsCOM.BoObjectTypes]::oInventoryTransferRequest)
                            if($DrfEntry -gt 0)
                            {
                                $ST.GetByKey($DrfEntry);
                                $ST.Lines.SetCurrentLine(0)
                                $ST.Lines.Quantity+=$Quantity
                                if(!$pfcCompany.InTransaction)
                                    {
                                        $pfcCompany.StartTransaction(); 
                                    }
                                $LogDateTime = Get-Date
                                [string]$LogDateTime + ' Przed aktualizacją dok.   przesunięcia: '  >> $LogFileName  
                                $message = $ST.Update();
                                $LogDateTime = Get-Date
                                [string]$LogDateTime + ' Po aktualizacji dok.   przesunięcia: '  >> $LogFileName  
                             if($message -lt 0)
                                {
                                    $err=$pfcCompany.GetLastErrorDescription()
                                    $ms = [string]::Format(" [Gniazdo]   Przesuniecie   nie zostało zaktualizowane `n`nSzczegóły: {0}`nSTUCode: {1} DocEntry{2}",$DrfEntry,$err,$SU_List); 
                                    $Object = 'MM_Create_Draft';
                                    $KeyName = 'DocEntry';
                                    $KeyValue = $DrfEntry;
                                    $Remarks = $ms;

                                    #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                    if($pfcCompany.InTransaction)
                                    {
                                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                    }
                    
                                    #$queryManagerLog.ClearParameters();
                                    #$queryManagerLog.AddParameter("Object",$Object);
                                    #$queryManagerLog.AddParameter("Key_Name",$KeyName);
                                    #$queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                    #$queryManagerLog.AddParameter("Remarks",$Remarks);
                                    #$dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                    continue;
                                }  
                            }
                            else
                            {
                            # $ST.DocObjectCode = [SAPbobsCOM.BoObjectTypes]::oInventoryTransferRequest;
                             $ST.FromWarehouse=$FromWhs
                             $ST.ToWarehouse=$ToWhs
                             $lines=$ST.Lines;
                             $lines.ItemCode = $ItemCode
                             $lines.WarehouseCode = $ToWhs
                             $lines.FromWarehouseCode = $FromWhs
                             $lines.Quantity = $Quantity

                             $lines.UserFields.Fields.Item("U_LineNum").Value = 1;
                             $lines.UserFields.Fields.Item("U_DocEntry").Value = $MorDocEntry.ToString()
                             $lines.UserFields.Fields.Item("U_ItemType").Value = "IT";
                             $lines.UserFields.Fields.Item("U_Revision").Value = "code00"
                             $lines.UserFields.Fields.Item("U_FromBinCode").Value =  $KWARANTANNA
                             $lines.UserFields.Fields.Item("U_ToBinCode").Value =$ToBinCode
                             if(!$pfcCompany.InTransaction)
                                    {
                                        $pfcCompany.StartTransaction(); 
                                    }
                                $LogDateTime = Get-Date
                                [string]$LogDateTime + ' Przed dodaniem dok. tymaczasowego przesunięcia: '  >> $LogFileName  
                               $message = $ST.Add();
                               $LogDateTime = Get-Date
                               [string]$LogDateTime + ' Po dodaniu dok. tymaczasowego przesunięcia: '  >> $LogFileName  
                             if($message -lt 0)
                                {
                                    $err=$pfcCompany.GetLastErrorDescription()
                                    $ms = [string]::Format(" [Gniazdo]   Przesuniecie   nie zostało zaktualizowane `n`nSzczegóły: {0}`nSTUCode: {1} DocEntry{2}",$pickOrder.DocNum,$err,$SU_List); 
                                    $Object = 'MM_Create_Draft';
                                    $KeyName = 'DocEntry';
                                    $KeyValue = $DrfEntry;
                                    $Remarks = $ms;

                                    #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                   if($pfcCompany.InTransaction){
                                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                    }
                    
                                    #$queryManagerLog.ClearParameters();
                                    #$queryManagerLog.AddParameter("Object",$Object);
                                    #$queryManagerLog.AddParameter("Key_Name",$KeyName);
                                    #$queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                    #$queryManagerLog.AddParameter("Remarks",$Remarks);
                                    #$dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                    continue;
                                }  
                            }
                        }
                        $LogDateTime = Get-Date
                        [string]$LogDateTime + ' Zamknięcie SU LIST: '  >> $LogFileName  
                         $lst=New-Object System.Collections.ArrayList;
                         $lst.AddRange($SU_List.ToString().Split(','));
                         
                         CloseSU -pfcCompany $pfcCompany -SUs $lst;
                         if($pfcCompany.InTransaction){
                                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Commit); 
                                    }
                                    }catch
                                    {
                                    $err=$pfcCompany.GetLastErrorDescription()
                                    $ms = [string]::Format(" [MMCreate ] globalexcetiptio  `n`nSzczegóły: {0}`nSTUCode: {1} DocEntry{2}",$pickOrder.DocNum,$err,$SU_List); 
                                    $Object = 'MM_Create';
                                    $KeyName = 'DocEntry';
                                    $KeyValue = $DrfEntry;
                                    $Remarks = $ms;

                                    #$pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback);
                                    Write-Host -BackgroundColor DarkRed -ForegroundColor White $ms
                                   if($pfcCompany.InTransaction){
                                        $pfcCompany.EndTransaction([CompuTec.ProcessForce.API.StopTransactionType]::Rollback); 
                                    }
                    
                                    #$queryManagerLog.ClearParameters();
                                    #$queryManagerLog.AddParameter("Object",$Object);
                                    #$queryManagerLog.AddParameter("Key_Name",$KeyName);
                                    #$queryManagerLog.AddParameter("Key_Value",$KeyValue);
                                    #$queryManagerLog.AddParameter("Remarks",$Remarks);
                                    #$dummy = $queryManagerLog.Execute($pfcCompany.Token); 
                                    continue;
                                    }
                }
           Start-Sleep -Seconds 5
}

