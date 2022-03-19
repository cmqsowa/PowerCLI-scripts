# This script extends the virtual hard disk size.
# extendVMDSize.ps1
# Cathy Sowa
# May 15, 2017

Connect-VIServer “<servername>”
Get-vm <vm> | get-HardDisk | Set-HardDisk –CapacityGB <decimalSize>
Disconnect-VIServer “<servername>”