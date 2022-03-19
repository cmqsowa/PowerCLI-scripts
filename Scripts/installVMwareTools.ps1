# This script installs VMware Tools silently
# installVMwareTools.ps1
# Created by Cathy Sowa
# May 15, 2017

$VM = Get-VM '<server>'
Mount-Tools -VM $VM
$DrvLetter=Get-WMIObject -Class 'Win32_CDROMDrive' ` -ComputerName $VM.Name ` | Where-Object {$_.VolumeName -match "VMwareTools"} | Select-Object -ExpandProperty Drive

$cmd="$($DrvLetter)\setup.exe /S /v`"/qn REBOOT=ReallySuppress ADDLOCAL=ALL`""

$go=Invoke-WMIMethod -path Win32_Process ` - Name Create ` -ComputerName $VM.Name ` -ArgumentList $cmd
if ($go.ReturnValue -ne 0)
{
	Write-Warning "Installer returned code $($go.ReturnValue)!Unmounting media"
	Dismount-Tools -VM $VM
}
else
{
	Write-Verbose "Tool installation triggered on $($VM.Name) media will be ejected upon completion."
}