ls Cert:\LocalMachine\CA

ls Cert:\LocalMachine\CA | select Thumbprint, NotBefore, NotAfter

ls Cert:\LocalMachine\CA | select Thumbprint, NotBefore, NotAfter , @{name = 'Days';expression={$_.NotAfter.Subtrack($_.NotBefore)}}

Get-Process

Get-Process |Sort-Object CPU -Descending

Get-Process |Sort-Object CPU -Descending | select ProcessName,@{Name='Minuty';expression={'{0:N0}'-f ($_.CPU/60)}} -First 5
Get-Process |Sort-Object CPU -Descending | select ProcessName,@{Name='Minuty';expression={'{0:N0}'-f ($_.CPU/60)}} -First 5






1.      ls Cert:\LocalMachine\CA

2.      ls Cert:\LocalMachine\CA | Select Thumbprint,NotBefore,NotAfter

3.      ls Cert:\LocalMachine\CA | Select Thumbprint,NotBefore,NotAfter,@{name='ValidDays';expression={$_.NotAfter.Subtract($_.NotBefore)}}

4.      Get-Process

5.      Get-Process | sort cpu -desc

6.      Get-Process | sort cpu -desc | select ProcessName,@{name='Cpu(minutes)';expression={$_.CPU/60}} -First 5

7.      Get-Process | sort cpu -desc | select ProcessName,@{name='Cpu(minutes)';expression={'{0:N0}' -f ($_.CPU/60)}} -First 5