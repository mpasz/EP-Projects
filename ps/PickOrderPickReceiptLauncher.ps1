#
# PickOrderPickReceiptLauncher.ps1
#
Clear-Host
function preCheck($pfcCompany)
{
    $select="select  top 1 t0.""DocEntry""
from
""@CT_PF_PRE2""  t0 
where 
IFNULL(t0.""U_Receipted"",'N')<>'Y';"
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


$LogFileName = 'C:\Temp\PickOrderPicReceiptLog.txt';
$LogDateTime = Get-Date
[string]$LogDateTime + ' Uruchomienie skryptu: '  >> $LogFileName
. $PSScriptRoot\lib\References.ps1 
ReferencjeSAP
. $PSScriptRoot\lib\ConnectionAdapter.ps1
. $PSScriptRoot\lib\Logger.ps1
$SCRIPT_FILE_NAME = $PSScriptRoot + "\PickOrderPickReceipt.ps1"
$WATCHDOG_FILENAME = $PSScriptRoot + "\watchdog\PickOrderPickReceipt.watchdog"; 
$SCRIPT_FILE_NAME_LOCK = $SCRIPT_FILE_NAME + ".lock"
. $SCRIPT_FILE_NAME
$scriptName=$MyInvocation.MyCommand.Name
$connectionAdapter = [ConnectionAdapter]::new();
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
try {
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Przed połączniem: '  >> $LogFileName
    $isConnected = $connectionAdapter.Connect($pfcCompany,$scriptName);
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Po połączniu: '  >> $LogFileName
    if($isConnected -eq $true)
    {
        $maxNumberOfItterations = 100000 #$connectionAdapter.getMaxNumberOfItteration()
        $ittertaionNumber = 1;

        while($true)
        {

            if($ittertaionNumber -ge $maxNumberOfItterations)
            {
                exit
            }
            $isrunning=$connectionAdapter.CheckConnection($pfcCompany.Token)
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
                        Remove-Item $SCRIPT_FILE_NAME_LOCK
                    }
                }
                #endregion

                if($runScript)
                {
                    New-Item $SCRIPT_FILE_NAME_LOCK -type file
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Przed wywolaniem procedury: '  >> $LogFileName
                    CreateDocuments $pfcCompany $WATCHDOG_FILENAME;
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Po wywolaniu procedury: '  >> $LogFileName
                    Remove-Item $SCRIPT_FILE_NAME_LOCK
                }
                Start-Sleep -Seconds 5
            }
            else
            {
                Start-Sleep -Seconds 5
            }
            $ittertaionNumber++;
        }
    }
    else
    {
        logConnectionError $connectionAdapter $pfcCompany $scriptName
        Start-Sleep -Seconds 20
    }
} catch {
    $exceptionMsg = $_.Exception.Message;`
    logConnectionError $connectionAdapter $pfcCompany $scriptName $exceptionMsg
}




