dd-Type -Path 'C:\Computec\Powershell\Interop.SAPbobsCOM.dll';
[System.Reflection.Assembly]::LoadWithPartialName("Sap.Data.Hana")
function ReferencjeSAP()
{
    add-type -Path "C:\Computec\Powershell\Interop.SAPbobsCOM.dll"
    add-type -Path "C:\Computec\Powershell\Interop.SAPbouiCOM.dll"
}