//
//  CPHelperCommon.m
//  com.scottdensmore.CPHelperTool
//
//  Created by Scott Densmore on 3/29/25.
//

#import <Foundation/Foundation.h>

#pragma mark - Time Machine Commands
NSString * const kCPHelperEnableTMCommand = @"EnableTM";
NSString * const kCPHelperEnableTMCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableTimeMachine";
NSString * const kCPHelperDisableTMCommand = @"DisableTM";
NSString * const kCPHelperDisableTMCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableTimeMachine";
NSString * const kCPHelperStartBackupTMCommand = @"StartBackupTM";
NSString * const kCPHelperStartBackupTMCommandAuthRightName = @"com.scottdensmore.CPHelperTool.startBackupTimeMachine";
NSString * const kCPHelperStopBackupTMCommand = @"StopBackupTM";
NSString * const kCPHelperStopBackupTMCommandAuthRightName = @"com.scottdensmore.CPHelperTool.stopBackupTimeMachine";

#pragma mark - Internet Sharing Commands
NSString * const kCPHelperEnableISCommand = @"EnableIS";
NSString * const kCPHelperEnableISCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableInternetSharing";
NSString * const kCPHelperDisableISCommand = @"DisableIS";
NSString * const kCPHelperDisableISCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableInternetSharing";

#pragma mark - Firewall Commands
NSString * const kCPHelperEnableFirewallCommand = @"EnableFirewall";
NSString * const kCPHelperEnableFirewallCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableFirewall";
NSString * const kCPHelperDisableFirewallCommand = @"DisableFirewall";
NSString * const kCPHelperDisableFirewallCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableFirewall";

#pragma mark - Display Settings Commands
NSString * const kCPHelperSetDisplaySleepTimeCommand = @"SetDisplaySleepTime";
NSString * const kCPHelperSetDisplaySleepTimeCommandAuthRightName = @"com.scottdensmore.CPHelperTool.setDisplaySleepTime";

#pragma mark - Printer Sharing Commands
NSString * const kCPHelperEnablePrinterSharingCommand = @"EnablePrinterSharing";
NSString * const kCPHelperEnablePrinterSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enablePrinterSharing";
NSString * const kCPHelperDisablePrinterSharingCommand = @"DisablePrinterSharing";
NSString * const kCPHelperDisablePrinterSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disablePrinterSharing";

#pragma mark - TFTP Commands
NSString * const kCPHelperEnableTFTPCommand = @"EnableTFTPCommand";
NSString * const kCPHelperEnableTFTPCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableTFTPCommand";
NSString * const kCPHelperDisableTFTPCommand = @"DisableTFTPCommand";
NSString * const kCPHelperDisableTFTPCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableTFTPCommand";

#pragma mark - FTP Commands
NSString * const kCPHelperEnableFTPCommand = @"EnableFTPCommand";
NSString * const kCPHelperEnableFTPCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableFTPCommand";
NSString * const kCPHelperDisableFTPCommand = @"DisableFTPCommand";
NSString * const kCPHelperDisableFTPCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableFTPCommand";

#pragma mark - File Sharing Commands
NSString * const kCPHelperEnableAFPFileSharingCommand = @"EnableAFPFileSharing";
NSString * const kCPHelperEnableAFPFileSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableAFPFileSharing";
NSString * const kCPHelperDisableAFPFileSharingCommand = @"DisableAFPFileSharing";
NSString * const kCPHelperDisableAFPFileSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableAFPFileSharing";
NSString * const kCPHelperEnableSMBFileSharingCommand = @"EnableSMBFileSharing";
NSString * const kCPHelperEnableSMBFileSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableSMBFileSharing";
NSString * const kCPHelperDisableSMBFileSharingCommand = @"DisableSMBFileSharing";
NSString * const kCPHelperDisableSMBFileSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableSMBFileSharing";

NSString * const kCPHelperSMBPrefsFilePath = @"/Library/Preferences/SystemConfiguration/com.apple.smb.server";
NSString * const kCPHelperSMBSyncToolFilePath = @"/usr/libexec/samba/smb-sync-preferences";
NSString * const kCPHelperSMBSyncToolFilePathMavericks = @"/usr/libexec/smb-sync-preferences";

NSString * const kCPHelperFileSharingStatusKey = @"Disabled";
NSString * const kCPHelperFilesharingConfigResponse = @"sharingStatus";
NSString * const kCPHelperAFPServiceName = @"com.apple.AppleFileServer";
NSString * const kCPHelperSMBDServiceName = @"com.apple.smbd";

#pragma mark - Web Sharing Commands
NSString * const kCPHelperEnableWebSharingCommand = @"EnableWebSharing";
NSString * const kCPHelperEnableWebSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableWebSharing";
NSString * const kCPHelperDisableWebSharingCommand = @"DisableWebSharing";
NSString * const kCPHelperDisableWebSharingCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableWebSharing";

#pragma mark - Remote Login Commands
NSString * const kCPHelperEnableRemoteLoginCommand = @"EnableRemoteLogin";
NSString * const kCPHelperEnableRemoteLoginCommandAuthRightName = @"com.scottdensmore.CPHelperTool.enableRemoteLogin";
NSString * const kCPHelperDisableRemoteLoginCommand = @"DisableRemoteLogin";
NSString * const kCPHelperDisableRemoteLoginCommandAuthRightName = @"com.scottdensmore.CPHelperTool.disableRemoteLogin";

#pragma mark - Misc
NSString * const kCPHelperInstallCommandLineToolCommand = @"InstallTool";
NSString * const kCPHelperInstallCommandLineToolSrcPath = @"srcPath";
NSString * const kCPHelperInstallCommandLineToolName = @"toolName";
NSString * const kCPHelperInstallCommandLineToolResponse = @"Success";

