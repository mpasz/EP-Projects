#
# Script.ps1
#
Clear-Host
 
. $PSScriptRoot\lib\References.ps1 
. $PSScriptRoot\lib\ConnectionAdapter.ps1
. $PSScriptRoot\lib\Logger.ps1
. $PSScriptRoot\ProcessOrderLine.ps1 

$scriptName=$MyInvocation.MyCommand.Name
$connectionAdapter = [ConnectionAdapter]::new();
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()

try {
    $isConnected = $connectionAdapter.Connect($pfcCompany,$scriptName);
    if($isConnected -eq $true)
    {
        while($true)
        {
            $isrunning=$connectionAdapter.CheckConnection($pfcCompany.Token)
            if( $isrunning -eq 0)
            {
                exit 
            }
            $guid=GetNextOrder -pfcCompany $pfcCompany  
            if($guid -gt 0)
            { 
                    $RanNumber = Get-Random -Minimum 0 -Maximum 4
                    $stopwath2= New-Object System.Diagnostics.Stopwatch
                    $stopwath2.Start()
                    ProcessOrder  -guid $guid -pfcCompany $pfcCompany 
                    Write-Host -ForegroundColor Green $guid " processing Time total =" $stopwath2.Elapsed.TotalMilliseconds 
            }
            else
            {
                Start-Sleep -Seconds 5
            }
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