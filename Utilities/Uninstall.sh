#! /bin/sh

# <codex>
# <abstract>Script to remove everything installed by the sample.</abstract>
# </codex>

# This uninstalls everything installed by the sample.  It's useful when testing to ensure that 
# you start from scratch.

sudo launchctl bootout system/com.scottdensmore.CPHelperTool
sudo launchctl unload /Library/LaunchDaemons/com.com.scottdensmore.CPHelperTool.plist
sudo rm /Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist
sudo rm /Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool

rm ~/Library/Preferences/com.scottdensmore.ControlPlane.plist
rm -rf ~Library/Caches/com.scottdensmore.ControlPlane

# Time Machine
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableTimeMachine"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableTimeMachine"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.startBackupTimeMachine"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.stopBackupTimeMachine"

# Internet Sharing Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableInternetSharing"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableInternetSharing"

# Firewall Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableFirewall"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableFirewall"

# Display Settings Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.setDisplaySleepTime"

# Printer Sharing Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enablePrinterSharing"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disablePrinterSharing"

# TFTP Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableTFTPCommand"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableTFTPCommand"

# FTP Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableFTPCommand"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableFTPCommand"

# File Sharing Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableAFPFileSharing"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableAFPFileSharing"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableSMBFileSharing"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableSMBFileSharing"

# Web Sharing Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableWebSharing"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableWebSharing"

# Remote Login Commands
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.enableRemoteLogin"
sudo security -q authorizationdb remove "com.scottdensmore.CPHelperTool.disableRemoteLogin"
