#
# MM_Create.ps1
#
Clear-Host
. $PSScriptRoot\lib\References.ps1 
ReferencjeSAP
. $PSScriptRoot\lib\ConnectionAdapter.ps1
. $PSScriptRoot\lib\Logger.ps1
.  $PSScriptRoot\ProcessOrderLine.ps1

$scriptName=$MyInvocation.MyCommand.Name
$connectionAdapter = [ConnectionAdapter]::new();
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
try {
    $isConnected = $connectionAdapter.Connect($pfcCompany,$scriptName);
    if($isConnected -eq $true) 
    {
        $select="select * from CT_PRODUKCJA_RzadaniePrzesunieciaGrouped order by ""U_FromBinCode"" ,""U_ToBinCode""";
    
        $a= New-Object CompuTec.Core.DI.Database.QueryManager
        $a.CommandText=$select;
        
        $rec=$a.Execute($pfcCompany.Token);
        $lst=New-Object System.Collections.ArrayList;


    
        $fromBinCode="";
        $toBinCode="";
        for($i=0 ;$i -lt $rec.RecordCount ;$i++)
        {

            if( $fromBinCode -ne $rec.Fields.Item("U_FromBinCode").Value -or  $toBinCode -ne $rec.Fields.Item("U_ToBinCode").Value)
            {
                if($i-ne 0)
                {
                    $ret= $ST.Add();
                    if($ret -ne 0)
                    {
                        $pfcCompany.getLastErrorDescription()

                    }else
                    {
                        CloseSU -pfcCompany $pfcCompany -SUs $lst;
                    }
                    # Dodaj
                }
            # nowy dokument         
                $ST= $pfcCompany.CreateSapObject([SAPbobsCOM.BoObjectTypes]::oInventoryTransferRequest)
                $ST.DocObjectCode=[SAPbobsCOM.BoObjectTypes].oInventoryTransferRequest;
                $ST.FromWarehouse=$rec.Fields.Item("FromWhsCode").Value
                $ST.ToWarehouse=$rec.Fields.Item("ToWhsCode").Value
                $lines=$ST.Lines;
                $lst.Clear()
            }
            $fromBinCode=$rec.Fields.Item("U_FromBinCode").Value
            $toBinCode=$rec.Fields.Item("U_ToBinCode").Value
            $SuCode=$rec.Fields.Item("Units").Value;
            $lst.AddRange($SuCode.ToString().Split(','));
            
            $lines.ItemCode =  $rec.Fields.Item("ItemCode").Value
            $lines.WarehouseCode = $rec.Fields.Item("ToWhsCode").Value
            $lines.FromWarehouseCode = $rec.Fields.Item("FromWhsCode").Value
            $lines.Quantity = $rec.Fields.Item("Quantity").Value
            $lines.UserFields.Fields.Item("U_LineNum").Value = 1;
            $lines.UserFields.Fields.Item("U_DocEntry").Value = $rec.Fields.Item("U_DocEntry").Value.ToString()
            $lines.UserFields.Fields.Item("U_ItemType").Value = "IT";
            $lines.UserFields.Fields.Item("U_Revision").Value = "code00"
            $lines.UserFields.Fields.Item("U_FromBinCode").Value =  $fromBinCode
            $lines.UserFields.Fields.Item("U_ToBinCode").Value =$toBinCode
            $lines.Add();
            $rec.MoveNext();
        
        }
        if($rec.RecordCount -gt 0)
        {
            # Dodaj
            $ret= $ST.Add();
            if($ret -ne 0)
            {
                $pfcCompany.getLastErrorDescription()
            } else
            {
                CloseSU -pfcCompany $pfcCompany -SUs $lst;
            }
        }
        exit ;
    } else
    {
        logConnectionError $connectionAdapter $pfcCompany $scriptName
        Start-Sleep -Seconds 20
    }
} catch {
    $exceptionMsg = $_.Exception.Message;
    logConnectionError $connectionAdapter $pfcCompany $scriptName $exceptionMsg
}