# CleanMgrHDCleanup.ps1
# Created by C Sowa
# May 15, 2017

Get-Module -Name VMware.*
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
$VCServer = "cavmman1.staff.laker.int"
Connect-VIServer $VCServer 

# Targeted Datastore
$datastore = "SC-StaffCluster"

#Filename where results are dumped
$ExportFilename = "C:\VMHDCleanMgrComplete.txt"

# Resource pool for targeted VMs
$AllVMs = Get-ResourcePool "CathyTest" | Get-VM

$report = @() 

FOREACH ($VM in $AllVMs) { 
	
$VMName = $VM.Name

	$vmview = $vm | Get-View
		
			$vmview = $vm | Get-View	
	
	# VMCalculations
		$VMCapacityGB = [System.Convert]::ToDecimal($vm.ProvisionedSpaceGB)
		$VMUsedSpaceGB = [System.Convert]::ToDecimal($vm.UsedSpaceGB)
		$VMFreeSpaceGB = $VMCapacityGB - $VMUsedSpaceGB
		
	# WinCalculations
		$drive = Get-WMIObject -Class win32_LogicalDisk -computer $VMName -filter "DriveType=3" | Select-Object -ExpandProperty DeviceID 
		$winStats = Get-WMIObject -Class win32_LogicalDisk -computer $VMName -filter "DeviceID='C:'" 
		$winCapacity = [System.Convert]::ToDecimal($winStats.Size)
		$winCapacityGB = ($WinCapacity/1GB)
		$winFreeSpace = [System.Convert]::ToDecimal($winStats.FreeSpace)
		$winFreeSpaceGB = ($winFreeSpace/1GB)
		
		$spaceDiff = $winFreeSpaceGB - $VMFreeSpaceGB
			
	#Sets Report Variables
		FOREACH ($drive in $vmview) {
		
		$row = "" | select VMNAME, DATASTORE, VM_CAPACITY_GB, VM_USEDSPACE_GB, VM_FREESPACE_GB, WIN_CAPACITY_GB, WIN_FREESPACE_GB, FREESPACE_DIFFERENCE
		
		$row.VMNAME = $vm.name               
		$row.DATASTORE = $datastore
		$row.VM_CAPACITY_GB = [math]::Round($VMCapacityGB)
        $row.VM_USEDSPACE_GB = [math]::Round($VMUsedSpaceGB)
		$row.VM_FREESPACE_GB = [math]::Round($VMFreeSpaceGB)
		$row.WIN_CAPACITY_GB = [math]::Round($winCapacityGB)
		$row.WIN_FREESPACE_GB = [math]::Round($winFreeSpaceGB)
		$row.FREESPACE_DIFFERENCE = [math]::Round($spaceDiff)
		$report += $row
		
		Write-Host "VM Name: " $VMName " VM Free Space: " $VMFreeSpaceGB " Win Free Space: " $winFreeSpaceGB " Difference Between Reported Windows and VM Free Space: " $spaceDiff
	
		}
		
		#Creating PsExec folder on $VM
			Write-Host "Creating new directory for PsExec on $VM"
			New-Item \\$VMName\c$\psexec -type directory
		
		#Copying psexec.exe to $VM
			Write-Host "Copying PsExec to $VM"
			Copy-Item c:\psexec\* -Destination \\$VMName\c$\psexec\
		
		#Set Clean Manager registry settings for items to remove
			Write-Host 'Clearing CleanMgr.exe automation settings.'
			Write-Host 'Setting registry settings to remove items'
			$cleanMgrSet = "c:\psexec\psexec.exe \\$VMName DiskCleanup.bat"
			Invoke-Command -scriptblock {Invoke-Expression $cleanMgrSet}
			
            #Starting Clean Manager
			Write-Host 'Starting CleanMgr'
			$cleanMgrStart = "c:\psexec\psexec.exe \\$VMName cleanmgr.exe -Argument '/sagerun:777'" 
			Invoke-Command -scriptblock {Invoke-Expression $cleanMgrStart}
		
		#Deleting PsExec folder on $VM
			Write-Host "Removing PsExec from $VM"
			Remove-Item \\$VMName\c$\psexec\ -recurse -force
				
	#Report on files
		$report | Export-Csv $ExportFilename -NoTypeInformation
	
} #END FOREACH VM IN ALLVMS

Disconnect-VIServer $VCServer -Confirm:$False