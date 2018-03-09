[string]$SQLServer = "BETA"
[string]$SQLDBName = "MG_GT"
[string]$SQLQuery = $("select 
AnRyzBHP,
AnRyzJak,
AnRyzDP,
AnRyzLog,
AnRyzFin,
T1.Data
--,* 
from wusr_vv_mg_ZapOfertowe_new_OGF t0 (nolock)
	inner join mg_nagdow t1 (nolock) on t0.nagid = t1.nagid
where 
t1.Data < GetDate()
and 
(AnRyzBHP is null or AnRyzJak is null or AnRyzDP  is null or AnRyzLog is null or AnRyzFin is null)")

$Command = New-Object System.Data.SqlClient.SqlCommand
$Command.Connection = $Connection

$SQLConnection = New-Object System.Data.SqlClient.SqlConnection
$SQLConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName;Integrated Security = True;"



$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SQLQuery
$SqlCmd.Connection = $SQLConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)


$DataSet.Tables[0] | Out-File "C:\Moje Dane\Moje\EP-Project\query_result.txt"
Get-Content "C:\Moje Dane\Moje\EP-Project\query_result.txt" | select T1.Data, AnRyzBHP, AnRyzJak, AnRyzDP,AnRyzLog,AnRyzFin  |Out-GridView



