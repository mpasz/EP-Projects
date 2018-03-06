#
# MorFromDeliveryLauncher.ps1
#
Clear-Host
function preCheck($pfcCompany)
{
    $select="select DL.""DocEntry"" from PDN1 DL WHERE DL.""U_Niezaplanowane"" != 'N' AND DL.""U_Niezaplanowane"" != 'S'"
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

. $PSScriptRoot\lib\References.ps1 
. $PSScriptRoot\lib\ConnectionAdapter.ps1
. $PSScriptRoot\lib\Logger.ps1
$SCRIPT_FILE_NAME = $PSScriptRoot + "\MorFromDelivery.ps1"
$SCRIPT_FILE_NAME_LOCK = $SCRIPT_FILE_NAME + ".lock"
. $SCRIPT_FILE_NAME
 
$scriptName=$MyInvocation.MyCommand.Name
$connectionAdapter = [ConnectionAdapter]::new();
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
try {
    $isConnected = $connectionAdapter.Connect($pfcCompany,$scriptName);
 
    if($isConnected -eq $true)
    {
    
        $maxNumberOfItterations = $connectionAdapter.getMaxNumberOfItteration()
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
                exit 
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
                    if($diffTime.TotalMinutes -gt 60){
                        $runScript = $true;
                        Remove-Item $SCRIPT_FILE_NAME_LOCK
                    }
                }
                #endregion

                if($runScript)
                {
                    New-Item $SCRIPT_FILE_NAME_LOCK -type file
                    CreateMors($pfcCompany);
                    Remove-Item $SCRIPT_FILE_NAME_LOCK
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
