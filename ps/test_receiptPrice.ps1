 #[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$PSScriptRoot = "C:\Computec\Powershell"
. $PSScriptRoot\ProcessOrderLine.ps1
 
 Referencje
 $pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
 

$SQLQUERY_PICK_ORDER_LIST = "select * from CT_PRODUKCJA_PWRWGrouped";



#Database connection

Write-Host -BackgroundColor Blue 'Connecting to SAP...'
$pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()

$code= Connect2 -pfcCompany $pfcCompany

if($code -eq $true) {
 
 GetReceiptPrice -pfcCompany $pfcCompany   -ItemCode 'WG-00660-00362'  -Quantity 8  -DocEntry 1163

}