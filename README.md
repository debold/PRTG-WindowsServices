PRTG-WindowsServices
====================
Using PRTG to monitor Windows services can be done with the integrated services sensor. However, this sensor can only monitor **one** service at the same time. This can be very useful to track memory or CPU usage of services, but in most cases you simply like to know, if all services are running as inteded. An there is no built-in means for that.

Therefore I created this script sensor. It will monitor your *Windows* server for any service configured for automatic start, that is not running. It will alert you, whenever it finds an automatic service not running. As you all know Windows quiet well, there are some services, that are configured for automatic start, but stopped by default. To cope with this situation, this script has several ways to exclude such services on global scale or per server.

Usage
-----
The script is implemented as custom sensor "EXE/Script" in PRTG. So you need to copy the ps1 file to the corresponding script path of your PRTG installation (on each **probe**), usually `${env:ProgramFiles(x86)}\PRTG Network Monitor\Custom Sensors\EXE`.

Using the sensor requires at least the following parameters:

Setting|Value
---|---
Parameters|-ComputerName %host
Security Context|Use Windows credentials of parent device
Scanning Interval|at least 5 minutes

Parameters
----------
You can further customize the way the script works using the following parameters:

### ComputerName
The hostname or IP address of the Windows machine to be checked. Should be set to %host in the PRTG parameter configuration.

### IgnorePattern
Regular expression to describe the INTERNAL name (not display name) of Windows services not to be monitored. Easiest way is to use a simple enumeration of service names.

Example: `^(gpsvc|WinDefend|WbioSrvc)$`

### UserName
Provide the Windows user name to connect to the target host via WMI. Better way than explicit credentials is to set the PRTG sensor to launch the script in the security context that uses the "Windows credentials of parent device".

### Password
Provide the Windows password for the user specified to connect to the target machine using WMI. Better way than explicit credentials is to set the PRTG sensor to launch the script in the security context that uses the "Windows credentials of parent device".

Service exceptions
------------------
As mentioned above, you can exclude services from being monitored. You can either use the **parameter IgnorePattern** to exclude a service on sensor basis, or set the **variable $IgnoreScript** within the script. Both variables take a regular expression as input to provide maximum flexibility. These regexes are then evaluated againt the **internal service name**, not the displayname.

By default, the $IgnoreScript varialbe looks like this:

```powershell
$IgnoreScript = '^(MapsBroker|sppsvc|RemoteRegistry|WbioSrvc|clr_optimization_.+|CDPSvc)$'
```

As you can see, e.g. MapsBroker is excluded by its full name, whereby the .NET Optimization uses a different notation, as the service may include its version number in its name. For more information about regular expressions in PowerShell, visit [Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions).
