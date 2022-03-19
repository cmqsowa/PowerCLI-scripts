# Port Scan on servers using nmap
# PortScanQuery.ps1
# Created by Cathy Sowa
# May 15, 2017

Set-ExecutionPolicy Bypass -Force
Import-Module ActiveDirectory
Add-PSSnapin vm* -ErrorAction SilentlyContinue
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false

#Connects to server with credentials. All virtual servers are on same cluster "Campus Servers"
$FileName = "C:\temp\portscanresults.txt"
$ArgumentList = "-T1 -PN"

Connect-VIServer "<server>"

#Sets variable to get names of all VM host names (names of each server)
$vmscan = Get-VM
$vmreport=@()


<# Sets up scan for all vms using Get-VM command. Will run without giving error report.
nmap options say to identify ports on each $vm using the $vm.name pulled in the $vmscan.
Invoke-Command runs nmap command. #>

foreach ($vm in $vmscan) {
		$vmname = $vm.name
		if ($vmname -like "dmz-*") {
			$vmname=$vmname.Substring(4)
			}
		if ($vmname -like "*ded") {
			continue
			}
		if ($vmname -like "*old") {
			continue
			}
		$nmap = "nmap $vmname -script-args $ArgumentList >> $Filename"
		Invoke-Command -scriptblock {Invoke-Expression $nmap}
		$vmreport += $vmname
	}
	
DisConnect-VIServer "casvrvmman2"
