{\rtf1\ansi\ansicpg1252\cocoartf2580
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fmodern\fcharset0 CourierNewPSMT;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
{\info
{\author Cathy Sowa}}\margl1079\margr1079\vieww12840\viewh16440\viewkind1
\deftab720
\pard\pardeftab720\ri0\partightenfactor0

\f0\fs21 \cf0 # This script moves volumes between VMWare datastores and runs \'91Sdelete\'92 \
# application before reprovisioning as thin provisioned volumes in the original \
# datastore.\
# sdeleteHDProvisionResize.ps1\
# Created by C Sowa\
# May 15, 2017\
\
Get-Module -Name VMware.*\
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false\
$VCServer = "<server>"\
Connect-VIServer $VCServer \
\
# Datastore for migration to different provision type\
$resizeVolume = "<ResizeVolume>"\
\
# Current Datastore Location\
$datastore = "<datastore>"\
\
# Limit for discrepancy of reported VM HD size and Windows HD size.\
$resizeLimit = "10"\
\
# Export filename to dump results\
$ExportFilename = "C:\\VMHDResizeComplete.txt"\
\
# Resource Pool with targeted VMs\
$AllVMs = Get-ResourcePool "Pool" | Get-VM\
\
$report = @() \
\
FOREACH ($VM in $AllVMs) \{ \
	\
$VMName = $VM.Name\
	\
	IF ($VM.PowerState -ne "PoweredOn") \{\
             add-content -path "C:\\VMListSkipped.txt" -value "...Skipping $VMName - Powered OFF!!"\
        continue\
        \}\
	\
	$vmview = $vm | Get-View	\
	\
	# VMCalculations\
		$VMCapacityGB = [System.Convert]::ToDecimal($vm.ProvisionedSpaceGB)\
		$VMUsedSpaceGB = [System.Convert]::ToDecimal($vm.UsedSpaceGB)\
		$VMFreeSpaceGB = $VMCapacityGB - $VMUsedSpaceGB\
		\
	# WinCalculations\
		$drive = Get-WMIObject -Class win32_LogicalDisk -computer $VMName -filter "DriveType=3" | Select-Object -ExpandProperty DeviceID \
		$winStats = Get-WMIObject -Class win32_LogicalDisk -computer $VMName -filter "DeviceID='C:'" \
		$winCapacity = [System.Convert]::ToDecimal($winStats.Size)\
		$winCapacityGB = ($WinCapacity/1GB)\
		$winFreeSpace = [System.Convert]::ToDecimal($winStats.FreeSpace)\
		$winFreeSpaceGB = ($winFreeSpace/1GB)\
		\
		$spaceDiff = $winFreeSpaceGB - $VMFreeSpaceGB\
			\
	#Sets Report Variables\
		FOREACH ($drive in $vmview) \{\
		\
		$row = "" | select VMNAME, DATASTORE, VM_CAPACITY_GB, VM_USEDSPACE_GB, VM_FREESPACE_GB, WIN_CAPACITY_GB, WIN_FREESPACE_GB, FREESPACE_DIFFERENCE\
		\
		$row.VMNAME = $vm.name               \
		$row.DATASTORE = $datastore\
		$row.VM_CAPACITY_GB = [math]::Round($VMCapacityGB)\
        $row.VM_USEDSPACE_GB = [math]::Round($VMUsedSpaceGB)\
		$row.VM_FREESPACE_GB = [math]::Round($VMFreeSpaceGB)\
		$row.WIN_CAPACITY_GB = [math]::Round($winCapacityGB)\
		$row.WIN_FREESPACE_GB = [math]::Round($winFreeSpaceGB)\
		$row.FREESPACE_DIFFERENCE = [math]::Round($spaceDiff)\
		$report += $row\
		\
		Write-Host "VM Name: " $VMName " VM Free Space: " $VMFreeSpaceGB " Win Free Space: " $winFreeSpaceGB " Difference Between Reported Windows and VM Free Space: " $spaceDiff\
		\
		IF ($spaceDiff -ge $resizeLimit) \{	\
			#Creating SDELETE folder on $VM\
				Write-Host "Creating new directory for Sdelete and PsExec on $VM"\
				New-Item \\\\$VMName\\c$\\sdelete -type directory\
		\
			#Copying sdelete.exe and psexec.exe to $VM\
				Write-Host "Copying Sdelete and PsExec to $VM"\
				Copy-Item c:\\sdelete\\* -Destination \\\\$VMName\\c$\\sdelete\\\
		\
			#Executing SDELETE using Remote Powershell Tool on $VM\
				$SDelete = "c:\\sdelete\\psexec.exe \\\\$VMName c:\\sdelete\\sdelete.exe -accepteula -z c$"\
				Invoke-Command -scriptblock \{Invoke-Expression $SDelete\}\
		\
			#Deleting SDELETE folder on $VM\
				Remove-Item \\\\$VMName\\c$\\sdelete\\ -recurse -force\
				\
			#Relocating $VM to $resizeVolume \
				Move-VM -VM $VMName -Datastore $resizeVolume -DiskStorageFormat EagerZeroedThick\
	\
			#Replacing $VM in $datastore\
				Move-VM -VM $VMName -Datastore $datastore -DiskStorageFormat Thin\
		\
		\} #END IF RESIZELIMIT\
		\
	#Report on files\
		$report | Export-Csv $ExportFilename -NoTypeInformation\
		\
	\}  #END FOREACH VMNAME IN ALLVMS\
	\
\} #END FOREACH VM IN ALLVMS\
\
Disconnect-VIServer $VCServer -Confirm:$False\
}