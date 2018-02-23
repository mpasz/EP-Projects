[System.Reflection.Assembly]:: LoadFile("C:\Program Files (x86)\CompuTec\CompuTec LabelPrinting\Drivers\CrystalDriver.dll")
[System.Reflection.Assembly]:: LoadFile("C:\Program Files (x86)\CompuTec\CompuTec LabelPrinting\CompuTec.LabelPrinting.Drivers.dll")

$dr=  New-Object CrystalDriver.CrystalDriver
 [System.