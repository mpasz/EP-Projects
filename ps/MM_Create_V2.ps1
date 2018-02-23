. $PSScriptRoot\ProcessOrderLine.ps1
. $PSScriptRoot\test_.ps1
 $DATABASE_NAME = 'TEST_PROD_NS_080517' 
 Referencje
 $pfcCompany = [CompuTec.ProcessForce.API.ProcessForceCompanyInitializator]::CreateCompany()
 
 $isConnected= testconnect5 -pfcCompany $pfcCompany
   MM_beetweenLocations  $pfcCompany