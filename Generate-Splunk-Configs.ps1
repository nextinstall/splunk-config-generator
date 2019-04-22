##################################################################################################
# SPLUNK config generator
#
# Script dynamically generates the inputs.conf based off the HOSTNAME variable and saves inputs.conf
# Outputs.conf is also generated but not unique per server or written out at this time.
#
# You MUST have already installed Splunk or have the folder stucture in place to output anything.
# Script will stop and start Splunk Forwarder when done to start tracking new log sources.
#
# You MUST update Line 19 [$index] with your index name!
#
# Tweak or tune blacklisted events to stop them from being forwarded. 
#
# Uncomment 165 & 170 to write out outputs.conf if needed
#
#
#
# Written by Tom Gregory for public use - 2019-04-20
# 
###################################################################################################


#### VARIABLES ####
$now = Get-Date
$index = "MyIndexName"

#Security Event Blacklist - Don't forward to Splunk
$blacklist = "26401,5157,5156,4690,4667,4666,4665,4658,4656"

$Hostname = (hostname).ToUpper()
$x64path = "C:\Program Files\SplunkUniversalForwarder\etc\system\local"
$x86path = "C:\Program Files (x86)\SplunkUniversalForwarder\etc\system\local"
$found = $false
###################



##########################################
#SPLUNK outputs.conf config file contents#
##########################################
$outputfile = "
# Generated @ $now
[tcpout]
defaultGroup = XYZ
disabled = false

[tcpout:XYZ]
server = xxxxxxx

"


########################################
# SPLUNK inputs.conf config generator  #
########################################
$file ="
# Generated @ $now
[default]
host = $Hostname

[script://`$SPLUNK_HOME\bin\scripts\splunk-wmi.path]
disabled = 0

[monitor://C:\Windows\System32\LogFiles\Firewall\]
disabled = 0
index = $index
sourcetype=WindowsFirewall


[WinEventLog://Application]
disabled = 0
start_from = oldest
current_only = 0
checkpointInterval = 5
index = $index


[WinEventLog://Security]
disabled = 0
start_from = oldest
current_only = 0
evt_resolve_ad_obj = 1
checkpointInterval = 5
blacklist = $blacklist 
index = $index


[WinEventLog://System]
disabled = 0
start_from = oldest
current_only = 0
checkpointInterval = 5
index = $index


[WinEventLog://Active Directory Web Services]
disabled = 0
index = $index
queue = parsingQueue
sourcetype = WinEventLog:Active-Directory-Web-Services


[WinEventLog://DFS Replication]
disabled = 0
index = $index
queue = parsingQueue
sourcetype = WinEventLog:DFS-Replication


[WinEventLog://Directory Service]
disabled = 0
index = $index
queue = parsingQueue
sourcetype = WinEventLog:Directory-Service


[WinEventLog://Microsoft-Windows-NTLM/Operational]
disabled=0
index = $index


[WinEventLog://Microsoft-Windows-DNSServer/Audit]
disabled=0
index = $index


[WinEventLog://Microsoft-Windows-GroupPolicy/Operational]
disabled=0
index = $index


[WinEventLog://Microsoft-Windows-PowerShell/Operational]
disabled = 0
index = $index
sourcetype = WinEventLog:PowerShell-Operational


[WinEventLog://Windows PowerShell]
checkpointInterval = 5
current_only = 0
disabed = 0
index = $index
sourcetype = WinEventLog:Powershell
start_from = oldest


[WinEventLog://Microsoft-Windows-SMBServer/Security]
disabled=0
index = $index


[WinEventLog://Microsoft-Windows-TerminalServices-LocalSessionManager/Operational]
disabled=0
index = $index


[WinEventLog://Microsoft-Windows-Windows Firewall With Advanced Security/Firewall]
disabled=0
index = $index


[monitor://D:\IQService\logs\IQTrace.log]
sourcetype=IQTrace

[script://$SPLUNK_HOME\bin\scripts\splunk-wmi.path]
disabled = 0

"

if (Test-Path $x64path){
    $file | Out-File "$x64path\inputs.conf" -Force
    #$outputfile | Out-File "$x64path\outputs.conf" -Force
    $found=$true
}
if (Test-Path $x86path){
    $file | Out-File "$x86path\inputs.conf" -Force
    #$outputfile | Out-File "$x86path\outputs.conf" -Force
    $found=$true
}

if ($found){
    Start-sleep -Seconds 5
        if (Get-Service -Name SplunkForwarder -ErrorAction SilentlyContinue){
        Get-Service -Name SplunkForwarder | Stop-Service
   
        }
    Start-sleep -Seconds 15
        if ((Get-Service -Name SplunkForwarder -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status) -ne 'Running'){
        Get-Service -Name SplunkForwarder | Start-Service
   
        }else{
            Write-host -BackgroundColor Red "`nSplunk is running but never stopped... Manually stop/start SplunkForwarder!"
            Write-host "`n`nRestart-Service -Name SplunkForwarder"
        }
}