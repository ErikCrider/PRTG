<#
PRTG Audit
This script will pull all devices that are in PRTG, count the number of sensors that exist for each found device.
The number of sensors does not determine if its properly monitored, but gives an idea of how many sensors are applied
It also looks for all Windows Servers in AD and compares them against the objects in PRTG, and marks that as true or false
Files are output to the C:\Temp directory and include the Date as a part of the name

This script pulls from Active Directory. You may need to get lists of non-AD objects as well. Unix/Linux, Network devices, etc.


Prerequisites:
Powershell v5 or higher
Powershell module: PRTGAPI 
    Install-Module -Name PrtgAPI

Changes needed to make this work in your environment
Line 26 - update with the FQDN of your PRTG server


Author: Erik Crider
Date: 11/09/2020


#>

Connect-PrtgServer -Server prtg.contoso.com 


## Variable declaration
$date = (get-date -uformat "%m-%d-%Y-%R" | ForEach-Object { $_ -replace ":", "." }) 
$FilepathServers = "c:\temp\Servers" + $Date+'.txt' 
$FilepathPRTGAudit = "c:\temp\PRTGAudit" + $Date+'.csv' 
$FilepathGoodServers = "c:\temp\GoodServers" + $Date+'.txt' 
$FilepathUnpingableServers = "c:\temp\UnpingableServers" + $Date+'.txt' 
$FilePathPRTGContains = "c:\temp\PRTGContains" + $Date+'.csv' 
$dataColl = @()
$alldev = @()

## Get all PRTG Devices
$Alldev = Get-Device
## Get all PRTG Sensors
$AllSensors = Get-Sensor

## Create a file containing each of the devices with a count of how many sensors it has
foreach ($Dev in $alldev) {
$NumSensors = @()
$NumSensors = ($AllSensors | where {$_.parentid -eq $dev.id}).count
$dataObject = New-Object PSObject
Add-Member -inputObject $dataObject -memberType NoteProperty -name "DeviceName" -value $Dev
Add-Member -inputObject $dataObject -memberType NoteProperty -name "DeviceID" -value $Dev.ID
Add-Member -inputObject $dataObject -memberType NoteProperty -name "Probe" -value $Dev.Probe
Add-Member -inputObject $dataObject -memberType NoteProperty -name "SensorCount" -value $NumSensors
$dataColl += $dataObject
}
$dataColl 

## Output
$dataColl | Export-Csv $FilepathPRTGAudit -NoTypeInformation


## Get all ADComputer objects with attribute OperatingSystem like "Windows Server"
$GoodServerList = @()
$UnpingableServerList = @()
Get-ADComputer -Filter {( OperatingSystem -Like '*Windows Server*') } | sort name | select -expandproperty name | Out-File $FilepathServers

$ServerList = Get-content $FilepathServers

##  Attempt to ping each server in the list, separate into two variables with only the pingable servers going forward 
foreach ($serverName in $Serverlist){
If (test-connection -ComputerName $servername -Quiet -Count 1){
$GoodServerList += $Servername
} else {
$UnpingableServerList +=$servername}
}


## Output. Can be reviewed if needed
$GoodServerList | Out-File $FilepathGoodServers
$UnpingableServerList | Out-File $FilepathUnpingableServers


## Create file containing ADComputer objects and determine if this is in PRTG
$PRTGContains = @()
Foreach ($srv in $Datacoll){
$IsinPRTG = ($srv.devicename -in $goodserverlist)
$ADComputerObject = New-Object PSObject
Add-Member -inputObject $ADComputerObject -memberType NoteProperty -name "ComputerName" -value $Srv.Devicename
Add-Member -inputObject $ADComputerObject -memberType NoteProperty -name "IsInPRTG" -value $IsinPRTG
$PRTGContains += $ADComputerObject
}

##Output
$PRTGContains | Export-Csv $FilePathPRTGContains -NoTypeInformation
