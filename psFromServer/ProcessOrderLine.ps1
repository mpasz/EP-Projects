#
# ProcessOrderLine.ps1
#

function ProcessOrder($guid,$pfcCompany)
{
try{

$queryA="
select * from ""@CT_ZNP""
where  ""DocEntry""=@Guid
" 
$linieQuery="select * from CT_BOM_LINIEZTECHNOLOGII where ""U_ItemCode""=@ItemCode and ""U_Revision""=@Revision and ""U_RtgCode""=@Rtg"
     $a= New-Object CompuTec.Core.DI.Database.QueryManager
     $a.CommandText=$queryA;
     $a.AddParameter("Guid",$guid);
     $rec=$a.Execute($pfcCompany.Token);

    
 
     $HasCNP=$false
     
        $stopwath= New-Object System.Diagnostics.Stopwatch
$stopwath.Start();
       $mo = $pfcCompany.CreatePFObject( [CompuTec.ProcessForce.API.Core.ObjectTypes]::ManufacturingOrder);
        if($rec.Fields.Item("U_Revision").Value -eq "NS")
        {
        $mo.Series=81
        }
        else
        {
        $mo.Series=70
        }

       $mo.U_ItemCode=$rec.Fields.Item("U_ItemCode").Value;
       $mo.U_Revision =$rec.Fields.Item("U_Revision").Value;
       $mo.U_RtgCode =$rec.Fields.Item("U_Tech").Value;
       $mo.U_RequiredDate=$rec.Fields.Item("U_DataP").Value;
       $mo.U_Quantity=$rec.Fields.Item("U_PlanQty").Value
       $mo.CalculateManufacturingTimes($true);
       $mo.U_Status=[CompuTec.ProcessForce.API.Enumerators.ManufacturingOrderStatus]::"Released";
       $mo.U_Remarks=$rec.Fields.Item("U_Comments").Value
       $mo.UDFItems.Item("U_DrawNoRaw").Value=$rec.Fields.Item("U_NrRysSur").Value
       $mo.UDFItems.Item("U_DrawNoFinal").Value=$rec.Fields.Item("U_NrRysGot").Value

       if(($rec.Fields.Item("U_BT").Value -eq "PWRW" -or $rec.Fields.Item("U_BT").Value -eq "67" ) -and $mo.U_RtgCode[12]-eq 'P' )
       {
           $mo.UDFItems.Item("U_Linia1").Value=$rec.Fields.Item("U_LProd").Value
           $mo.UDFItems.Item("U_Zmiana1").Value=$rec.Fields.Item("U_Zmiana").Value
           $mo.UDFItems.Item("U_Data1").Value=$rec.Fields.Item("U_DataP").Value

            $lq= New-Object CompuTec.Core.DI.Database.QueryManager
             $lq.CommandText=$linieQuery;
             $lq.AddParameter("ItemCode",$mo.U_ItemCode);
             $lq.AddParameter("Revision",$mo.U_Revision);
             $lq.AddParameter("Rtg",$mo.U_RtgCode);
             $recl=$lq.Execute($pfcCompany.Token);
           
             $start=$rec.Fields.Item("U_LProd").Value;
             $resultpos=0
             $i=0
             for($resultpos=1; $resultpos -le 10; $resultpos++)
             {
                $linia=$recl.Fields.Item("U_Linia"+[string]$resultpos).Value;
                if( $start -eq $linia)
                {
                    break;
                }
             }
             for($i=1;$i -le 10;$i ++)
             {
                $linia=$recl.Fields.Item("U_Linia"+[string]($resultpos+$i-1)).Value;
                if([string]::IsNullOrEmpty($linia)-eq $true)
                    {
                    break
                    }

                $mo.UDFItems.Item("U_Linia"+[string]$i).Value= $linia;
                $mo.UDFItems.Item("U_Zmiana"+[string]$i).Value=$rec.Fields.Item("U_Zmiana").Value
                $mo.UDFItems.Item("U_Data"+[string]$i).Value=$rec.Fields.Item("U_DataP").Value
                $mo.UDFItems.Item("U_Ilosc"+[string]$i).Value=$mo.U_Quantity
                $mo.UDFItems.Item("U_SumaPodzialek"+[string]$i).Value=$recl.Fields.Item("U_SumaPodzialek"+[string]($resultpos+$i-1)).Value
                $mo.UDFItems.Item("U_IlNaZawieszce"+[string]$i).Value=$recl.Fields.Item("U_IlNaZawieszcze"+[string]($resultpos+$i-1)).Value
                $mo.UDFItems.Item("U_IlNaPodzialce"+[string]$i).Value=$recl.Fields.Item("U_IlNaPodzialce"+[string]($resultpos+$i-1)).Value

             }

       }
       else{
           $mo.UDFItems.Item("U_Linia1").Value=$rec.Fields.Item("U_LProd").Value
           $mo.UDFItems.Item("U_Zmiana1").Value=$rec.Fields.Item("U_Zmiana").Value
           $mo.UDFItems.Item("U_Data1").Value=$rec.Fields.Item("U_DataP").Value
           $reklam =$rec.Fields.Item("U_Reklam").Value
           if($reklam -eq "T")
           {
           $mo.UDFItems.Item("U_Reklamacja").Value="Y"
           }else
           {
           $mo.UDFItems.Item("U_Reklamacja").Value="N"

           }
       }
       $added=$false
       #$pfcCompany.EndTranaction([CompuTec.ProcessForce.API.StopTransactionType]::Commit)
       if($mo.Add() -eq 0)
       {
        $b= New-Object CompuTec.Core.DI.Database.QueryManager
        $b.CommandText="call CT_CloseZNP( @Code,@Success,@DocNum,@Error)";
        $b.AddParameter("Code",$guid);
        $b.AddParameter("DocNum", $mo.DocNum); 
        $b.AddParameter("Success", 1); 
        $b.AddParameter("Error", "");
        $recb=$b.Execute($pfcCompany.Token);
        $added=$true;
       }else
       {
         $b= New-Object CompuTec.Core.DI.Database.QueryManager


        $b.CommandText="call CT_CloseZNP( @Code,@Success,@DocNum,@Error)";
        $b.AddParameter("Code",$guid);
        $b.AddParameter("DocNum", $mo.DocNum); 
        $b.AddParameter("Success", 0); 
        $b.AddParameter("Error",  $mo.ErrorDescription);
        $recb=$b.Execute($pfcCompany.Token);
       }

      $stopwath.Stop()
      Write-Host "Adding Document Cust Rows" $stopwath.Elapsed.TotalMilliseconds  "[ms]"
      }catch
      {
         $b= New-Object CompuTec.Core.DI.Database.QueryManager
        $b.CommandText="call CT_CloseZNP( @Code,@Success,@DocNum,@Error)";
        $b.AddParameter("Code",$guid);
        $b.AddParameter("DocNum", $mo.DocNum); 
        $b.AddParameter("Success", 0); 
        $b.AddParameter("Error", $_.Exception.Message);
        $recb=$b.Execute($pfcCompany.Token);
      }

 return 
}

function CloseSU( $pfcCompany, $SUs)
{

 $update="call CT_Su_WykonaneRzadanie (@Code)  "
    $select="call ""GetNextGuid"""
   
   

    foreach($si in $SUs)
    {
     $b= New-Object CompuTec.Core.DI.Database.QueryManager
    $b.CommandText=$update;     $b.CommandText=$update;
        $b.AddParameter("Code",$si);
        $b.Execute($pfcCompany.Token);
    }
      $c= New-Object CompuTec.Core.DI.Database.QueryManager
      $c.CommandText='call CT_CheckBigBox()' ;
      $c.Execute($pfcCompany.Token);
}

  
function CloseSUAfterReceipt( $pfcCompany, $SUs)
{

 $update="call CT_Su_WykonanePrzyjecie (@Code,@Qty)  "
    
   

    foreach($si in $SUs)
    {     
        $b= New-Object CompuTec.Core.DI.Database.QueryManager
        $b.CommandText=$update;
        $b.CommandText=$update;
        $tab=$si.Split(';')
        $code=$tab[0];

        if([string]::IsNullOrEmpty($code)-eq $true)
        {
                continue;
        }
        $qty=[int]$tab[1]
        $b.AddParameter("Code",$code);
        $b.AddParameter("Qty",$qty);

        $b.Execute($pfcCompany.Token);
    }

}
function GetNextOrder($pfcCompany)
{
    $select="call ""GetNextGuid"""
    $a= New-Object CompuTec.Core.DI.Database.QueryManager
    $a.CommandText=$select;
  
     $rec=$a.Execute($pfcCompany.Token);
     if($rec.RecordCount-ne 0)
     {


        return $rec.Fields.Item(0).Value
     }
     else
    {
        return ""
    }
}
function TestOrders($number)
{

#connect
 
 
#Database connection
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
$pfcCompany.UserName = "marekt"
$pfcCompany.Password = "1234"
$pfcCompany.SQLPassword = "Ab123456"
$pfcCompany.SQLServer = "10.0.0.72:30115"
$pfcCompany.SQLUserName = "SYSTEM"
$pfcCompany.Databasename = "TEST_20151130"
$pfcCompany.LicenseServer = "10.0.0.75:40000"
$pfcCompany.DbServerType = [SAPbobsCOM.BoDataServerTypes]::dst_HANADB
$code = 0;

$code = $pfcCompany.Connect()
if($code -eq 1)
{
$select="call ""GetNextGuid"""
$a= New-Object CompuTec.Core.DI.Database.QueryManager


     $a.CommandText=$select;
     while($true)
     {
    # $a.AddParameter("Guid",$guid);
     $rec=$a.Execute($pfcCompany.Token);
     if($rec.RecordCount-eq 0)
        
        {
        Write-Host $number " Waiting..."
        Start-Sleep 5

        }else
        { 
         $rec.Fields.Item(0).Value
        Write-Host $number   " Found"   $rec.Fields.Item(0).Value
       return  $rec.Fields.Item(0).Value
        }
     }
}
else
{
    Write-Host -BackgroundColor Red -ForegroundColor White 'Connection failed'
}
}


function CreateMMTransferRequest()
{

#
  clear
  
 Referencje
 $pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
 
 $isConnected= Connect -pfcCompany $pfcCompany
  if($isConnected -eq $true)
 {


 }

}


function GetReceiptPrice( $pfcCompany ,$ItemCode,$Quantity,$DocEntry)
{
$dynQuery=[System.String]::Format("SELECT
 SUM(""TRansValue"") 
FROM (SELECT 
        CASE t0.""U_ItemType"" 
            WHEN 'HR' THEN (""TransValue"" - costingLines.""U_FixOH"" - costingLines.""U_VarOH"") / (1 +
             (costingLines.""U_FixOHPrct"" / 100) + (costingLines.""U_VarOHPrct"" / 100)) 
            ELSE t1.""TransValue"" 
        END AS ""TRansValue"" 
    FROM ""@CT_PF_MOR5"" t0 
        INNER JOIN ""@CT_PF_OMOR"" t2 ON t0.""DocEntry"" = t2.""DocEntry"" 
inner join OADM adm  on 1=1
        
        INNER JOIN OINM t1 ON t0.""U_OperType"" = t1.""TransType"" AND T0.""U_OperEntry"" = t1.""CreatedBy"" AND
             T0.""U_OperLine"" = t1.""DocLineNum"" 
        LEFT OUTER JOIN ""@CT_PF_OITC"" costing ON t0.""U_ItemType"" = 'HR' AND t0.""U_ItemCode"" = costing.""U_ItemCode"" AND
             t2.""U_Revision"" = costing.""U_RevCode"" AND COSTING.""U_CostCategoryCode"" = '000' 
        LEFT OUTER JOIN ""@CT_PF_ITC1"" costingLines ON costing.""Code"" = costingLines.""Code"" AND
             ((costingLines.""U_WhsCode"" = t0.""U_WhsCode"" and adm.""PriceSys""='Y')or(adm.""PriceSys""='N'))
    WHERE t0.""U_ItemType"" IN ('IT','HR','CP','SC') AND t0.""DocEntry"" = {0})",$DocEntry);


   
    $a= New-Object CompuTec.Core.DI.Database.QueryManager
    $a.CommandText=$dynQuery;
  
     $rec=$a.Execute($pfcCompany.Token);
     
     $RowValue =   $rec.Fields.Item(0).Value;
      $b= New-Object CompuTec.Core.DI.Database.QueryManager
      $b.CommandText="select ""Price"" from ""ITM1"" where ""ItemCode""=@ItemCode and ""PriceList""=@PriceList";

      $b.AddParameter("ItemCode",$ItemCode);
      $b.AddParameter("PriceList",2);
       $rec=$b.Execute($pfcCompany.Token);
     
     $price =   $rec.Fields.Item(0).Value;
      $val=        (($RowValue*-1)/$Quantity)+(0.78*$price);
      if ($val -lt 0)
      {
     
     return 0 ;
      } else 

      {
      return $val;
      } 
}