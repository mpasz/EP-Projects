
function preCheck($pfcCompany)
{
    $select="SELECT ""DocEntry"" FROM ""@CT_ZW_NAG"" WHERE IFNULL(""U_PickRelease"",'N') = 'T' AND IFNULL(""U_PickNo"",0) = 0"
    $a= New-Object CompuTec.Core.DI.Database.QueryManager
    $a.CommandText=$select;
  
    $rec=$a.Execute($pfcCompany.Token);
    if($rec.RecordCount-ne 0)
    {
        return $true;  
    }
    else
    {
        return $false
    }
}


#
# Script.ps1
#
clear
add-type -Path "C:\Computec\Powershell\Interop.SAPbobsCOM.dll"
add-type -Path "C:\Computec\Powershell\Interop.SAPbouiCOM.dll"
$SCRIPT_FILE_NAME = $PSScriptRoot + "\PickList_RD_Test.ps1"
$SCRIPT_FILE_NAME_LOCK = $SCRIPT_FILE_NAME + ".lock"
. $PSScriptRoot\ProcessOrderLine.ps1
. $SCRIPT_FILE_NAME

$DATABASE_NAME = 'TEST_PROD_NS_080517' 
 
 Referencje
 $pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
 
 $isConnected= testconnect3 -pfcCompany $pfcCompany
 if($isConnected -eq $true)
 {
    $sapCompany = $pfcCompany.SapCompany
    while($true)
    {
        $isrunnung=CheckConnection($pfcCompany.Token) 
        if( $isrunning -eq 0)
        {
            exit; 
        }
        $runScript = preCheck -pfcCompany $pfcCompany  
        if($runScript -eq $true)
        {
            #region this part of script is responsible for allowing only one execution of ZlecenieWysylki()
            if(Test-Path $SCRIPT_FILE_NAME_LOCK)
            {
                $runScript = $false;

                $file = Get-Item $SCRIPT_FILE_NAME_LOCK
                $creationTime = $file.CreationTime
                $currentTime = Get-Date
                $diffTime = $currentTime - $creationTime
                if($diffTime.TotalMinutes -gt 5){
                    $runScript = $true;
                }
             }
             #endregion

             if($runScript)
             {
                $stopwath= New-Object System.Diagnostics.Stopwatch
                $stopwath.Start()
                New-Item $SCRIPT_FILE_NAME_LOCK -type file
                PickList($sapCompany);
                Remove-Item $SCRIPT_FILE_NAME_LOCK
                $stopwath.Stop()
                Write-Host -ForegroundColor Green $guid " processing Time total =" $stopwath.Elapsed.TotalMilliseconds 
            }
         }
         else
         {
           Start-Sleep -Seconds 5
         }
    }
 }
 else
 {
    $msg = [string]::format("Bład połączenia.")
    Write-Host -ForegroundColor Red "NotConnected !!:  "
    logConnectionError($DATABASE_NAME,$msg,'PickList.ps1')
 }




