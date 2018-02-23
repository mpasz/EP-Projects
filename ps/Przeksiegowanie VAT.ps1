clear
# użycie biblioteki SAPbobsCOM.dll
add-type -Path "C:\Computec\Powershell\x64\Interop.SAPbobsCOM.dll"
#add-type -Path "C:\Computec\Powershell\Interop.SAPbouiCOM.dll"
$sapCompany = new-Object -ComObject SAPbobsCOM.Company
$sapCompany.LicenseServer = "10.211.83.97:40000"

$sapCompany.Server = "10.211.83.97:30015"
$sapCompany.DbServerType =[SAPbobsCOM.BoDataServerTypes]::dst_HANADB
#$sapCompany.DbServerType =9
$sapCompany.DbUserName = "SYSTEM"
$sapCompany.DbPassword = "DB#admin!15"
$sapCompany.CompanyDB = "KEA_PROD"

$sapCompany.UserName = "manager"
$sapCompany.Password = "kea2015"

$lErrCode = 0
$sErrMsg = ""

write-host   –backgroundcolor green –foregroundcolor white  ([Environment]::NewLine) "-------Start"  ([System.DateTime]::Now).ToString()  "---------"  ([Environment]::NewLine)
        
$lretcode = $sapCompany.Connect()


$query = "
select * from 
(
select
'Przeksięgowanie VAT' ""Memo""
,T0.""DocNum"" ""Ref1""
,T0.""NumAtCard"" ""Ref2""
,T0.""CardCode"" ""ShortName""
,0 ""LineNum""
,-""VatSum"" ""Credit""
,-""VatSumFC"" ""FCCredit""
,T0.""DocCur"" ""FCCurrency""
,t0.""DocDate"" ""DataKsieg""
,t0.""DocDueDate"" ""DataPlat""
,t0.""TaxDate"" ""DataDok""
,t0.""VatDate"" ""DataVat""

from opch t0
left outer join OJDT t2 on t0.""DocNum""=t2.""Ref1"" and t2.""Memo""='Przeksięgowanie VAT'
inner join OCRD T3 on t0.""CardCode""=t3.""CardCode"" and t3.""Country""='PL'
where 
t2.""TransId"" is null
and ""PaidToDate""=0
and ifnull(T0.""DocCur"",'PLN')<>'PLN'


union all

select
'Przeksięgowanie VAT' ""Memo""
,T0.""DocNum"" ""Ref1""
,T0.""NumAtCard"" ""Ref2""
,T0.""CardCode"" ""ShortName""
,1 ""LineNum""
,""VatSum"" ""Credit""
,0 ""FCCredit""
,'PLN' ""FCCurrency""
,t0.""DocDate"" ""DataKsieg""
,t0.""DocDueDate"" ""DataPlat""
,t0.""TaxDate"" ""DataDok""
,t0.""VatDate"" ""DataVat""


from opch t0
left outer join OJDT t2 on t0.""DocNum""=t2.""Ref1"" and t2.""Memo""='Przeksięgowanie VAT'
inner join OCRD T3 on t0.""CardCode""=t3.""CardCode"" and t3.""Country""='PL'
where 
t2.""TransId"" is null
and ""PaidToDate""=0
and ifnull(T0.""DocCur"",'PLN')<>'PLN'

)

order by ""Ref1"",""LineNum""
"


#$lretcode = $sapCompany.Connect()
IF ($lretcode -eq 0) 
        {
        write-host –backgroundcolor green –foregroundcolor white "Połączony"  ([Environment]::NewLine)
        
        $LastCode=0
        $Line=0
        $recordset = $sapCompany.GetBusinessObject([SAPbobsCOM.BoObjectTypes]"BoRecordset")
        $recordset.DoQuery($query);
        


        while ($recordset.EoF -eq $false) 
        {
           $Code=$recordset.Fields.Item("Ref1").Value
           
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
                        write-host –backgroundcolor red –foregroundcolor white "Błąd" $sapCompany.GetLastErrorDescription() ([Environment]::NewLine)
                        $err=$sapCompany.GetLastErrorDescription() 
                        #logCC $docentry $err "0"
                    }
               }
          
            
            

           $oMR = $sapCompany.GetBusinessObject([SAPbobsCOM.BoObjectTypes]"oJournalEntries")  
           $oMR.Reference = $recordset.Fields.Item("Ref1").Value; 
           $oMR.Reference2 = $recordset.Fields.Item("Ref2").Value; 
           $oMR.Memo = $recordset.Fields.Item("Memo").Value;
            
           $oMR.ReferenceDate = $recordset.Fields.Item("DataKsieg").Value; 
           $oMR.DueDate = $recordset.Fields.Item("DataPlat").Value; 
           $oMR.TaxDate = $recordset.Fields.Item("DataDok").Value; 
           $oMR.VATDate = $recordset.Fields.Item("DataVat").Value; 
           
           }  
               
       
           
           $oMR.Lines.ShortName=$recordset.Fields.Item("ShortName").Value
           $oMR.Lines.Credit=$recordset.Fields.Item("Credit").Value
           $oMR.Lines.FCCredit=$recordset.Fields.Item("FCCredit").Value
           $oMR.Lines.FCCurrency=$recordset.Fields.Item("FCCurrency").Value

           
           $LastCode=$recordset.Fields.Item("Ref1").Value
           
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
                write-host –backgroundcolor red –foregroundcolor white "Błąd" $sapCompany.GetLastErrorDescription() ([Environment]::NewLine)
                $err=$sapCompany.GetLastErrorDescription() 
                #logCC $docentry $err "0"
            }
    }
      
        
        $sapCompany.Disconnect()
    
    
    }
ELSE
    {
        write-host –backgroundcolor red –foregroundcolor white "Brak Polączenia!" $sapCompany.GetLastErrorDescription() ([Environment]::NewLine)
        #logCC $docentry  $sapCompany.GetLastErrorDescription() "0"  
    }

 write-host –backgroundcolor green –foregroundcolor white "-------END--------- "  ([Environment]::NewLine)
    
    
    
    
    
