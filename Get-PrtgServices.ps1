<#
    .SYNOPSIS
    Monitors Windows services that are configured for automatic start with PRTG.

    .DESCRIPTION
    Using WMI this script searches for Windows services configured for automatic start, that are not started. As there are
    some services, that are never running, but configured as auto-start by default, exceptions can be configured. These exceptions
    can be made within this script by changing the variable $IgnoreScript. This way, the change applies to all PRTG sensors 
    based on this script. If exceptions have to be made on a per sensor level, the script parameter $IgnorePattern can be used.

    Copy this script to the PRTG probe EXE scripts folder (${env:ProgramFiles(x86)}\PRTG Network Monitor\Custom Sensors\EXE)
    and create a "EXE/Script" sensor. Choose this script from the dropdown and set at least:

    + Parameters: -ComputerName %host
    + Security Context: Use Windows credentials of parent device
    + Scanning Interval: 5 minutes

    .PARAMETER ComputerName
    The hostname or IP address of the Windows machine to be checked. Should be set to %host in the PRTG parameter configuration.

    .PARAMETER IgnorePattern
    Regular expression to describe the INTERNAL name (not display name) of Windows services not to be monitored. Easiest way is to
    use a simple enumeration of service names.

    Example: ^(gpsvc|WinDefend|WbioSrvc)$

    .PARAMETER UserName
    Provide the Windows user name to connect to the target host via WMI. Better way than explicit credentials is to set the PRTG sensor
    to launch the script in the security context that uses the "Windows credentials of parent device".

    .PARAMETER Password
    Provide the Windows password for the user specified to connect to the target machine using WMI. Better way than explicit credentials is to set the PRTG sensor
    to launch the script in the security context that uses the "Windows credentials of parent device".

    .EXAMPLE
    Sample call from PRTG (EXE/Advanced sensor)
    Get-PrtgServices.ps1 -ComputerName %host

    .NOTES
    This script is based on the sample by Paessler (https://kb.paessler.com/en/topic/67869-auto-starting-services) and extends its
    capabilities at excluding services from monitoring.

    Author:  Marc Debold
    Version: 1.0
    Version History:
        1.0  08.01.2019  Initial release
#>
param(
    [string]$ComputerName = "",
    [string]$IgnorePattern = "",
    [string]$UserName = "",
    [string]$Password = ""
)

if ($ComputerName -eq "") {
    Write-Host "You must provide a computer name to connect to"
    Exit 2
}

# Error if there's anything going on
$ErrorActionPreference = "Stop"

# Generate Credentials Object, if provided via parameter
if ($UserName -eq "" -or $Password -eq "") {
   $Credentials = $null
} else {
    $SecPasswd  = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credentials= New-Object System.Management.Automation.PSCredential ($UserName, $secpasswd)
}

# hardcoded list that applies to all hosts
$IgnoreScript = '^(MapsBroker|sppsvc|RemoteRegistry|WbioSrvc|clr_optimization_.+)$'
$WmiQuery = "Select * from Win32_Service where StartMode='Auto' and State!='Running'"

# Get list of services that are not running and set to automatic.
try {
    if ($null -ne $Credentials) {
        $Services = Get-WmiObject -Query $WmiQuery -ComputerName $ComputerName  
    } else {
        $Services = Get-WmiObject -Query $WmiQuery -ComputerName $ComputerName -Credential $Credentials  
    }
} catch {
    Write-Host "Error connecting to $ComputerName ($($_.Exception.Message))"
    Exit 2
}

# Remove all services from ignore lists
$Services = $Services | Where-Object {$_.Name -notmatch $IgnoreScript}
if ($IgnorePattern -ne "") {
    $Services = $Services | Where-Object {$_.Name -notmatch $IgnorePattern}
}

$Count = ($Services | Measure-Object).Count

if ($Count -gt 0) {
    $ServiceList = "{0} ({1})" -f $Services[0].DisplayName, $Services[0].Name
    for ($i = 1; $i -lt $Count; $i++) {
        $ServiceList += ", {0} ({1})" -f $Services[$i].DisplayName, $Services[$i].Name
    }
    $ServiceList = ($Services | Select-Object -expand DisplayName) -join ", "
    Write-Host "$($Count):Automatic service(s) not running: $ServiceList"
    exit 1
} else {
    Write-Host "0:All automatic services are running."
    exit 0
}
