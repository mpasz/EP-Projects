$i = 0

while ($i -lt 10)
{
    $i++
    if ($i % 2 -eq 0)
    {
        Write-Host "$i is even"
    }
    else {
        Write-Host "$i is odd"
    }
}

$i = 0
while ($i -lt 100)
{
    $i++
    if ($i % 2 -eq 0)
    {
        Write-Host "$i is even"
    }
    else {
        Write-Host "$i is odd"
    }
    if($i -eq 10)
    {
        Write-Host "Jest dycha. Zawijam"
        break;
    }
}


#TEST 

$comp = "SAMSUUNG-LAPTOPMICHAL"

while ( -not (Test-Connection -ComputerName $comp -Count 1 -Quiet))
{
    Write-Warning "$comp is not reachable"
    Start-Sleep -Seconds 10
}
Write-Host "$comp reachable at $(Get-Date)"

#LAB
$i = 0
$imax = 30

$sourceFileName = ".\master.txt"
$destinationFolder = ".\distribution"


if( -not(Test-Path $destinationFolder) )
{
    New-Item -$destinationFolder -name "distribution" -ItemType "directory"
} 
else{
    Write-Host "katalog już istnieje"
} 

Test-Path $destinationFolder  # co zwraca funkcja Test-Path
Get-Help Test-Path -Online

while($i -lt $imax)
{
    $i++
    $DestinationFile = $i.txt
    $newFileName = Join-Path $destinationFolder $DestinationFile
    Copy-Item $sourceFileName $newFileName
    echo "File $newFileName has been created"
}







