# OS Version Scan for Servers in Active Directory\
# viewServerOS.ps1
# Cathy Sowa
# May 15, 2017

Set-ExecutionPolicy Bypass -Force
Import-Module ActiveDirectory
Add-PSSnapin vm* -ErrorAction SilentlyContinue
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false

$FileName = "C:\temp\OSversions.txt"

<# Sets up scan for all objects matching a "Windows Server" operating system.
sorts OS versions for each AD computer and reports results in file with DNSHostName and version. #>

Get-ADcomputer -filter "OperatingSystem -like '*Server*'" -property OperatingSystem | Select DNSHostName,OperatingSystem | Sort OperatingSystem > C:\test4.txt