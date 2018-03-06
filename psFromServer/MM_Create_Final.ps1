#
# MM_Create.ps1
#
Clear-Host
$LogFileName = 'C:\Temp\MMCreateLog.txt';
$LogDateTime = Get-Date
[string]$LogDateTime + ' Uruchomienie skryptu: '  >> $LogFileName
. $PSScriptRoot\lib\References.ps1 
ReferencjeSAP
. $PSScriptRoot\lib\ConnectionAdapter.ps1
. $PSScriptRoot\lib\Logger.ps1
.  $PSScriptRoot\ProcessOrderLine.ps1



function preCheck($pfcCompany)
{
    $select="SELECT ""U_DocEntry"" FROM CT_PRODUKCJA_RzadaniePrzesunieciaGrouped "
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


$SCRIPT_FILE_NAME = $PSScriptRoot + "\MM_Create_body.ps1"

$SCRIPT_FILE_NAME_LOCK = $SCRIPT_FILE_NAME + ".lock"
#. $PSScriptRoot\ProcessOrderLine.ps1
. $SCRIPT_FILE_NAME

$scriptName=$MyInvocation.MyCommand.Name
$connectionAdapter = [ConnectionAdapter]::new();
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
try {
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Przed polaczniem: '  >> $LogFileName
    $isConnected = $connectionAdapter.Connect($pfcCompany,$scriptName);
    $LogDateTime = Get-Date
    [string]$LogDateTime + ' Po polaczniu: '  >> $LogFileName
    if($isConnected -eq $true)
    {
        $maxNumberOfItterations = $connectionAdapter.getMaxNumberOfItteration()
        $ittertaionNumber = 1;
        #$sapCompany = $pfcCompany.SapCompany
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
                #region this part of script is responsible for allowing only one execution 
                if(Test-Path $SCRIPT_FILE_NAME_LOCK)
                {
                    $runScript = $false;

                    $file = Get-Item $SCRIPT_FILE_NAME_LOCK
                    $creationTime = $file.CreationTime
                    $currentTime = Get-Date
                    $diffTime = $currentTime - $creationTime
                    if($diffTime.TotalMinutes -gt 5){
                        $runScript = $true;
                        Remove-Item $SCRIPT_FILE_NAME_LOCK
                    }
                }
                #endregion

                if($runScript)
                {
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Przed wywolaniem procedury: '  >> $LogFileName
                # New-Item $SCRIPT_FILE_NAME_LOCK -type file
                    MM_beetweenLocations($pfcCompany);
                    $LogDateTime = Get-Date
                    [string]$LogDateTime + ' Po wywolaniu procedury: '  >> $LogFileName
                #  Remove-Item $SCRIPT_FILE_NAME_LOCK
                }
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
    $exceptionMsg = $_.Exception.Message;
    logConnectionError $connectionAdapter $pfcCompany $scriptName $exceptionMsg
}

