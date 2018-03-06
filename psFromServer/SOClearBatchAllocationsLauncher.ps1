#
# SOClearBatchAllocationsLauncher.ps1
#
function preCheck($pfcCompany) {
    $select = "WITH CTE AS (
                SELECT
                 T1.""DocEntry"", T1.""LineNum"", T4.""DistNumber""
                FROM ORDR T0
                 INNER JOIN RDR1 T1 ON T0.""DocEntry"" = T1.""DocEntry"" AND T1.""LineStatus"" = 'O'
                 INNER JOIN OITL T2 ON T1.""DocEntry"" = T2.""DocEntry"" AND T1.""LineNum"" = T2.""DocLine"" AND T2.""DocType"" = 17
                 INNER JOIN ITL1 T3 ON T2.""LogEntry"" = T3.""LogEntry""
                 INNER JOIN OBTN T4 ON T3.""ItemCode"" = T4.""ItemCode"" AND T3.""SysNumber"" = T4.""SysNumber""
                WHERE T0.""DocStatus"" = 'O' and T4.""Quantity"" > 0
                GROUP BY T1.""DocEntry"", T1.""LineNum"", T3.""SysNumber"", T4.""DistNumber""
                HAVING SUM(T3.""AllocQty"") <> 0
                ),

                CTE1 AS (
                SELECT 
                 T1.""OrderEntry"", T1.""OrderLine"", T3.""DistNumber""
                FROM OPKL T0
                 INNER JOIN PKL1 T1 ON T0.""AbsEntry"" = T1.""AbsEntry""
                 INNER JOIN PKL2 T2 ON T1.""AbsEntry"" = T2.""AbsEntry"" AND T1.""PickEntry"" = T2.""PickEntry""
                 INNER JOIN OBTN T3 ON T2.""SnBEntry"" = T3.""AbsEntry""
                WHERE T0.""Status"" = 'C'
                )

                SELECT
                 T0.""DocEntry""
                FROM CTE T0
                 INNER JOIN CTE1 T1 ON T0.""DocEntry"" = T1.""OrderEntry"" AND T0.""LineNum"" = T1.""OrderLine"" AND T0.""DistNumber"" = T1.""DistNumber""";
    $a = New-Object CompuTec.Core.DI.Database.QueryManager
    $a.CommandText = $select;
  
    $rec = $a.Execute($pfcCompany.Token);
    if ($rec.RecordCount -ne 0) {
        return $true;  
    }
    else {
        return $false
    }
}


Clear-Host
. $PSScriptRoot\lib\References.ps1 
ReferencjeSAP
. $PSScriptRoot\lib\ConnectionAdapter.ps1
. $PSScriptRoot\lib\Logger.ps1
$SCRIPT_FILE_NAME = $PSScriptRoot + "\SOClearBatchAllocations.ps1"
$SCRIPT_FILE_NAME_LOCK = $SCRIPT_FILE_NAME + ".lock"
. $PSScriptRoot\ProcessOrderLine.ps1
. $SCRIPT_FILE_NAME

$scriptName = $MyInvocation.MyCommand.Name 
$connectionAdapter = [ConnectionAdapter]::new();
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
 
try {
    $isConnected = $connectionAdapter.Connect($pfcCompany, $scriptName);
 
    if ($isConnected -eq $true) {
        $maxNumberOfItterations = $connectionAdapter.getMaxNumberOfItteration()
        $ittertaionNumber = 1;
        $sapCompany = $pfcCompany.SapCompany
        while ($true) {
            if ($ittertaionNumber -ge $maxNumberOfItterations) {
                exit;
            }
            $isrunning = $connectionAdapter.CheckConnection($pfcCompany.Token)  
            if ( $isrunning -eq 0) {
                exit; 
            }
            $runScript = preCheck -pfcCompany $pfcCompany  
            if ($runScript -eq $true) {
                #region this part of script is responsible for allowing only one execution of ZlecenieWysylki()
                if (Test-Path $SCRIPT_FILE_NAME_LOCK) {
                    $runScript = $false;

                    $file = Get-Item $SCRIPT_FILE_NAME_LOCK
                    $creationTime = $file.CreationTime
                    $currentTime = Get-Date
                    $diffTime = $currentTime - $creationTime
                    if ($diffTime.TotalMinutes -gt 5) {
                        $runScript = $true;
                        Remove-Item $SCRIPT_FILE_NAME_LOCK
                    }
                }
                #endregion
                if ($runScript) {
                    New-Item $SCRIPT_FILE_NAME_LOCK -type file
                    SOClearBatchAllocations($sapCompany);
                    Remove-Item $SCRIPT_FILE_NAME_LOCK
                }
            }
            else {
                Start-Sleep -Seconds 5
            }
            $ittertaionNumber++;
        }
    }
    else {
        logConnectionError $connectionAdapter $pfcCompany $scriptName
        Start-Sleep -Seconds 20
    } 
} catch {
    $exceptionMsg = $_.Exception.Message;
    logConnectionError $connectionAdapter $pfcCompany $scriptName $exceptionMsg
}




