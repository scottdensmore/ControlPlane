//
//  CPHelperCommon.h
//  ControlPlane
//
//  Created by Scott Densmore on 3/29/25.
//

#ifndef CPHelperCommon_h
#define CPHelperCommon_h

#pragma mark - Time Machine Commands
extern NSString * const kCPHelperEnableTMCommand;
extern NSString * const kCPHelperEnableTMCommandAuthRightName;
extern NSString * const kCPHelperDisableTMCommand;
extern NSString * const kCPHelperDisableTMCommandAuthRightName;
extern NSString * const kCPHelperStartBackupTMCommand;
extern NSString * const kCPHelperStartBackupTMCommandAuthRightName;
extern NSString * const kCPHelperStopBackupTMCommand;
extern NSString * const kCPHelperStopBackupTMCommandAuthRightName;

#pragma mark - Internet Sharing Commands
extern NSString * const kCPHelperEnableISCommand;
extern NSString * const kCPHelperEnableISCommandAuthRightName;
extern NSString * const kCPHelperDisableISCommand;
extern NSString * const kCPHelperDisableISCommandAuthRightName;

#pragma mark - Firewall Commands
extern NSString * const kCPHelperEnableFirewallCommand;
extern NSString * const kCPHelperEnableFirewallCommandAuthRightName;
extern NSString * const kCPHelperDisableFirewallCommand;
extern NSString * const kCPHelperDisableFirewallCommandAuthRightName;

#pragma mark - Display Settings Commands
extern NSString * const kCPHelperSetDisplaySleepTimeCommand;
extern NSString * const kCPHelperSetDisplaySleepTimeCommandAuthRightName;

#pragma mark - Printer Sharing Commands
extern NSString * const kCPHelperEnablePrinterSharingCommand;
extern NSString * const kCPHelperEnablePrinterSharingCommandAuthRightName;
extern NSString * const kCPHelperDisablePrinterSharingCommand;
extern NSString * const kCPHelperDisablePrinterSharingCommandAuthRightName;

#pragma mark - TFTP Commands
extern NSString * const kCPHelperEnableTFTPCommand;
extern NSString * const kCPHelperEnableTFTPCommandAuthRightName;
extern NSString * const kCPHelperDisableTFTPCommand;
extern NSString * const kCPHelperDisableTFTPCommandAuthRightName;

#pragma mark - FTP Commands
extern NSString * const kCPHelperEnableFTPCommand;
extern NSString * const kCPHelperEnableFTPCommandAuthRightName;
extern NSString * const kCPHelperDisableFTPCommand;
extern NSString * const kCPHelperDisableFTPCommandAuthRightName;

#pragma mark - File Sharing
extern NSString * const kCPHelperEnableAFPFileSharingCommand;
extern NSString * const kCPHelperEnableAFPFileSharingCommandAuthRightName;
extern NSString * const kCPHelperDisableAFPFileSharingCommand;
extern NSString * const kCPHelperDisableAFPFileSharingCommandAuthRightName;
extern NSString * const kCPHelperEnableSMBFileSharingCommand;
extern NSString * const kCPHelperEnableSMBFileSharingCommandAuthRightName;
extern NSString * const kCPHelperDisableSMBFileSharingCommand;
extern NSString * const kCPHelperDisableSMBFileSharingCommandAuthRightName;

extern NSString * const kCPHelperSMBPrefsFilePath;
extern NSString * const kCPHelperSMBSyncToolFilePath;
extern NSString * const kCPHelperSMBSyncToolFilePathMavericks;

extern NSString * const kCPHelperFileSharingStatusKey;
extern NSString * const kCPHelperFilesharingConfigResponse;
extern NSString * const kCPHelperAFPServiceName;
extern NSString * const kCPHelperSMBDServiceName;

# pragma mark - Web Sharing Commands
extern NSString * const kCPHelperEnableWebSharingCommand;
extern NSString * const kCPHelperEnableWebSharingCommandAuthRightName;
extern NSString * const kCPHelperDisableWebSharingCommand;
extern NSString * const kCPHelperDisableWebSharingCommandAuthRightName;

#pragma mark - Remote Login Commands
extern NSString * const kCPHelperEnableRemoteLoginCommand;
extern NSString * const kCPHelperEnableRemoteLoginCommandAuthRightName;
extern NSString * const kCPHelperDisableRemoteLoginCommand;
extern NSString * const kCPHelperDisableRemoteLoginCommandAuthRightName;

#pragma mark - Misc
extern NSString * const kCPHelperInstallCommandLineToolCommand;
extern NSString * const kCPHelperInstallCommandLineToolSrcPath;
extern NSString * const kCPHelperInstallCommandLineToolName;
extern NSString * const kCPHelperInstallCommandLineToolResponse;

#endif /* CPHelperCommon_h */
