//
//  CPHelperToolProtocol.h
//  ControlPlane
//
//  Created by Scott Densmore on 3/29/25.
//

#ifndef CPHelperToolProtocol_h
#define CPHelperToolProtocol_h

#import <Foundation/Foundation.h>

@protocol CPHelperToolProtocol

@required

#pragma mark - Helper Commands
- (void)connectWithEndpointReply:(void(^)(NSXPCListenerEndpoint * endpoint))reply;
    
// This command simply returns the version number of the tool.  It's a good idea to include a
// command line this so you can handle app upgrades cleanly.
- (void)getVersionWithReply:(void(^)(NSString * version))reply;

#pragma mark - Time Machine Commands
- (void)enableTimeMachineAuthorization:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)startBackupTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)stopBackupTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - Internet Sharing Commands
- (void)enableInternetSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableInternetSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - Firewall Commands
- (void)enableFirewallAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableFirewallAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - Display Settings Commands
- (void)setDisplaySleepTime:(NSInteger)minutes authorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - Printer Sharing Commands
- (void)enablePrinterSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disablePrinterSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - File Sharing Commands
- (void)enableAFPFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableAFPFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)enableSMBFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableSMBFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - TFTP Commands
- (void)enableTFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableTFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - FTP Commands
- (void)enableFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - Web Sharing Commands
- (void)enableWebSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableWebSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

#pragma mark - Remote Login Commands
- (void)enableRemoteLoginAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;
- (void)disableRemoteLoginAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply;

@end

#endif /* CPHelperToolProtocol_h */
