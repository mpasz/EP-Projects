for ($i = 0; $i -lt 10; $i++)
{
    Write-Host "$i"
}

$list = "one", "two","three","four","five"

foreach($x in $list)
{
    Write-Host "The current element is $x"
}

$list | ForEach-Object {Write-Host "The current element is $_"}

######LAAAABO######


$lista = "1","2","3","4"
$sciezka = "C:\temp"

foreach($x in $lista)
{
    New-Item $sciezka -Name "$x" -ItemType "file"
}

$files = Get-ChildItem $sciezka
$files



foreach($z in $files)
{
    $z.Encrypt()
    $z.IsReadOnly = $true
}

