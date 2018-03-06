clear
# użycie biblioteki SAPbobsCOM.dll
add-type -Path "C:\Computec\Powershell\Interop.SAPbobsCOM.dll"
add-type -Path "C:\Computec\Powershell\Interop.SAPbouiCOM.dll"
$Company = new-Object -ComObject SAPbobsCOM.Company
$Company.Server = "172.16.0.54:30015"
$Company.DbUserName = "SYSTEM"
$Company.DbPassword = "Ep*4321#"
$Company.CompanyDB = "SBOELECTROPOLI"
$Company.LicenseServer = "172.16.0.53:40000"
$Company.UserName = "manager"
$Company.Password = "1234"
$Company.DbServerType = [SAPbobsCOM.BoDataServerTypes]::dst_HANADB
$lErrCode = 0
$sErrMsg = ""


write-host   –backgroundcolor green –foregroundcolor white  ([Environment]::NewLine) "-------Start"  ([System.DateTime]::Now).ToString()  "---------"  ([Environment]::NewLine)
        
$lretcode = $Company.Connect()


$query = "
select top 10 
sum(t0.""InQty""-t0.""OutQty"") ""Qty""
,sum(case when t0.""InQty"">0 then (ABS(t0.""InQty""-t0.""OutQty"")*t2.""Price""*0.78) else 0 end) ""Debit""
,sum(case when t0.""OutQty"">0 then (ABS(t0.""InQty""-t0.""OutQty"")*t2.""Price""*0.78) else 0 end) ""Credit""
,case when t0.""InQty"">0 then '+' else '-' end ""Znak""
,'312-02' ""Account""
,'604' ""Account2""
,cast(t0.""TransType"" as int) ""TransType""
,t0.""CreatedBy""
,cast(t0.""BASE_REF"" as int) ""DocNum""
,t0.""DocDate""
,case when t0.""Warehouse"" like '%N' then 2 else 1 end ""BPLID""
from oinm t0
inner join oitm t1 on t0.""ItemCode""=t1.""ItemCode""
inner join itm1 t2 on t1.""ItemCode""=t2.""ItemCode"" and t2.""PriceList""=3
inner join oitb t3 on t1.""ItmsGrpCod""=t3.""ItmsGrpCod"" and t3.""ItmsGrpNam""='Detal finalny'
left outer join ojdt t4 on t0.""CreatedBy""=t4.""U_DEBaz"" and  t0.""TransType""=""U_TypBaz""--cast(t0.""TransType"" as nvarchar(30))=t4.""Ref1""
where t0.""TransType"" in ('59','60','13','15')
and ""TransValue""=0
--and ""Warehouse""='GW'
--and ""CreatedBy""=37368
and t2.""Price""<>0
and t4.""TransId"" is null
and t0.""DocDate"">='2017-12-19'
group by 
t0.""TransType""
,t0.""CreatedBy""
,t0.""BASE_REF""
,t0.""DocDate""
,case when t0.""InQty"">0 then '+' else '-' end 
,case when t0.""Warehouse"" like '%N' then 2 else 1 end 
having sum(""InQty""+""OutQty"")<>0
order by t0.""DocDate"",""TransType"",""CreatedBy""
"


#$lretcode = $sapCompany.Connect()
IF ($lretcode -eq 0) 
        {
        write-host –backgroundcolor green –foregroundcolor white "Połączony"  ([Environment]::NewLine)
        
        $LastCode=0
        $Line=0
        $recordset = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]"BoRecordset")
        $recordset.DoQuery($query);
        


        while ($recordset.EoF -eq $false) 
        {
           $Code=$recordset.Fields.Item("CreatedBy").Value
           
         if ($Code -ne $LastCode)
           {$line=0
           
                If ($LastCode -ne 0)
                {
                $retcode=$oMR.Add() 
                if ($retcode -eq 0) 
                    {
                        write-host "Dodano"
                        #logCC $docentry  "Dodano pomyślnie" "1"
                    } 
                
                    else
                    {
                        write-host –backgroundcolor red –foregroundcolor white "Błąd" $Company.GetLastErrorDescription() ([Environment]::NewLine)
                        $err=$Company.GetLastErrorDescription() 
                        #logCC $docentry $err "0"
                    }
               }
          
            
            

           $oMR = $Company.GetBusinessObject([SAPbobsCOM.BoObjectTypes]"oJournalEntries")  
           $oMR.Reference = $recordset.Fields.Item("TransType").Value; 
           $oMR.Reference2 =$recordset.Fields.Item("CreatedBy").Value;  # 'DWU'
           $oMR.Memo = 'Doksięgowanie wartości usługi'

           $oMR.UserFields.Fields.Item('U_TypBaz').Value=$recordset.Fields.Item("TransType").Value;   #[int]::Parse($recordset.Fields.Item("TransType").Value); 
           $oMR.UserFields.Fields.Item('U_DEBaz').Value=$recordset.Fields.Item("CreatedBy").Value; 
           $oMR.UserFields.Fields.Item('U_DNBaz').Value=$recordset.Fields.Item("DocNum").Value; 
            
           $oMR.ReferenceDate = $recordset.Fields.Item("DocDate").Value; 
           $oMR.DueDate = $recordset.Fields.Item("DocDate").Value; 
           $oMR.TaxDate = $recordset.Fields.Item("DocDate").Value; 
           $oMR.VATDate = $recordset.Fields.Item("DocDate").Value;

           
           }  
               
           
           $oMR.Lines.ShortName=$recordset.Fields.Item("Account").Value
           $oMR.Lines.Credit=$recordset.Fields.Item("Credit").Value
           $oMR.Lines.Debit=$recordset.Fields.Item("Debit").Value
           $oMR.Lines.BPLID = $recordset.Fields.Item("BPLID").Value;
           
           $oMR.Lines.Add() 

           $oMR.Lines.ShortName=$recordset.Fields.Item("Account2").Value
           $oMR.Lines.Credit=$recordset.Fields.Item("Debit").Value
           $oMR.Lines.Debit=$recordset.Fields.Item("Credit").Value
           $oMR.Lines.BPLID = $recordset.Fields.Item("BPLID").Value;
           
           $LastCode=$recordset.Fields.Item("CreatedBy").Value
           
           $line=1
           
           $recordset.MoveNext()
           
           #if($recordset.EoF -eq $false)
           #{
           # $oMR.Lines.Add()
           #}    
           
           $oMR.Lines.Add() 
      }
           
           
IF ($recordset.RecordCount -ne 0)  
   {
           $retcode=$oMR.Add()
              
        
        if ($retcode -eq 0) 
            {
                write-host "Dodano" ([Environment]::NewLine)
                #logCC $docentry  "Dodano pomyślnie" "1"
            } 
            
        else
            {
                write-host –backgroundcolor red –foregroundcolor white "Błąd" $Company.GetLastErrorDescription() ([Environment]::NewLine)
                $err=$Company.GetLastErrorDescription() 
                #logCC $docentry $err "0"
            }
    }
      
        
        $Company.Disconnect()
    
    
    }
ELSE
    {
        write-host –backgroundcolor red –foregroundcolor white "Brak Polączenia!" $Company.GetLastErrorDescription() ([Environment]::NewLine)
        #logCC $docentry  $sapCompany.GetLastErrorDescription() "0"  
    }

 write-host –backgroundcolor green –foregroundcolor white "-------END--------- "  ([Environment]::NewLine)
    
    
    
    
    
