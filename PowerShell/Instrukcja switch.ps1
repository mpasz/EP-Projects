$letter = 'c:'
$valueToReturn = "FreeSpace"

switch ($valueToReturn) {
    "FreeSpace" { Get-WmiObject win32_logicaldisk -Filter "DeviceId = '$letter'" | Select FreeSpace  }
    "TotalSpace" {Get-WmiObject win32_logicaldisk -Filter "DeviceId= '$letter'" | Select Size }
    Default {Get-WmiObject win32_logicaldisk -Filter "DeviceId='$letter'" | select @{n="Used"; e={$_.size - $_.FreeSpace} }}
}   

###LAB#####

$License = Get-WmiObject -Class SoftwareLicensingProduct -Filter "Name like '%Windows%' AND PartialProductKey <> null"
$License 

$licenseDescription = switch ($License.LicenseStatus) {
    0 {"Unlicensed" }
    1 {"Licensed"}
    2 {"OOBGrace"}
    3 {"OOTGrace"}
    4 {"NonGenuineGrace"}
    5 {"Notification"}
    6 {"ExtendedGrace"}
    Default {}
} 
$licenseDescription
echo "The system license status is $licenseDescription"

