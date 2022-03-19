{\rtf1\ansi\ansicpg1252\cocoartf2580
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fmodern\fcharset0 CourierNewPSMT;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
{\info
{\author Cathy Sowa}}\margl1079\margr1079\vieww12540\viewh16140\viewkind1
\deftab720
\pard\pardeftab720\ri0\partightenfactor0

\f0\fs21 \cf0 # OS Version Scan for Servers in Active Directory\
# viewServerOS.ps1\
# Cathy Sowa\
# May 15, 2017\
\
Set-ExecutionPolicy Bypass -Force\
Import-Module ActiveDirectory\
Add-PSSnapin vm* -ErrorAction SilentlyContinue\
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false\
\
$FileName = "C:\\temp\\OSversions.txt"\
\
<# Sets up scan for all objects matching a "Windows Server" operating system.\
sorts OS versions for each AD computer and reports results in file with DNSHostName and version. #>\
\
Get-ADcomputer -filter "OperatingSystem -like '*Server*'" -property OperatingSystem | Select DNSHostName,OperatingSystem | Sort OperatingSystem > C:\\test4.txt\
}