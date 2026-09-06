//
//  CPHelperTool.m
//  com.scottdensmore.CPHelperTool
//
//  Created by Scott Densmore on 3/29/25.
//

#import "CPHelperTool.h"
#import "CPHelperToolProtocol.h"
#import "CPHelperCommon.h"
#import "CPHelperCommandRunner.h"
#import "CPAuthorization.h"
#import "CPCommonConstants.h"

#include <errno.h>

@interface CPHelperTool () <NSXPCListenerDelegate, CPHelperToolProtocol>

@property (atomic, strong, readwrite) NSXPCListener *listener;

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;
- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command;
- (void)replyAfterRunning:(NSString *)path
                arguments:(NSArray<NSString *> *)arguments
            failureMessage:(NSString *)failureMessage
                    reply:(void (^)(BOOL success, NSError *error))reply;

@end

@implementation CPHelperTool

- (id)init
{
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperToolMachServiceName];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
    // Tell the XPC listener to start processing requests.
    [self.listener resume];
    
    // Run the run loop forever.
    [[NSRunLoop currentRunLoop] run];
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description
{
    return [NSError errorWithDomain:kHelperToolMachServiceName
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

// Check that the client denoted by authData is allowed to run the specified command.
// authData is expected to be an NSData with an AuthorizationExternalForm embedded inside.
- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command
{
    NSError *                   error;
    OSStatus                    err;
    OSStatus                    junk;
    AuthorizationRef            authRef;

    assert(command != nil);
    
    authRef = NULL;

    // First check that authData looks reasonable.
    error = nil;
    if ( (authData == nil) || ([authData length] != sizeof(AuthorizationExternalForm)) ) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
    }
    
    // Create an authorization ref from that the external form data contained within.
    
    if (error == nil) {
        err = AuthorizationCreateFromExternalForm([authData bytes], &authRef);
        
        // Authorize the right associated with the command.
        
        if (err == errAuthorizationSuccess) {
            AuthorizationItem   oneRight = { NULL, 0, NULL, 0 };
            AuthorizationRights rights   = { 1, &oneRight };

            oneRight.name = [[CPAuthorization authorizationRightForCommand:command] UTF8String];
            assert(oneRight.name != NULL);
            
            err = AuthorizationCopyRights(
                authRef,
                &rights,
                NULL,
                kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
                NULL
            );
        }
        if (err != errAuthorizationSuccess) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        }
    }

    if (authRef != NULL) {
        junk = AuthorizationFree(authRef, 0);
        assert(junk == errAuthorizationSuccess);
    }

    return error;
}

- (void)replyAfterRunning:(NSString *)path
                arguments:(NSArray<NSString *> *)arguments
            failureMessage:(NSString *)failureMessage
                    reply:(void (^)(BOOL success, NSError *error))reply
{
    int retValue = [CPHelperCommandRunner runExecutable:path arguments:arguments];
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:failureMessage]);
    }
}

#pragma mark - NSXPCListenerDelegate implementation
// Called by our XPC listener when a new connection comes in.  We configure the connection
// with our protocol and ourselves as the main object.
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    assert(listener == self.listener);
    assert(newConnection != nil);

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CPHelperToolProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

#pragma mark - CPHelperToolProtocol implementation

// XPC service support).  Called by the XPC service to get an endpoint for our listener.  It then
// passes this endpoint to the app so that the sandboxed app can talk us directly.
- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint *))reply
{
    reply([self.listener endpoint]);
}

// Returns the version number of the tool.  Note that never requires authorization.
- (void)getVersionWithReply:(void(^)(NSString * version))reply
{
    // We specifically don't check for authorization here.  Everyone is always allowed to get
    // the version of the helper tool.
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    reply(bundleVersion);
}


#pragma mark - Time Machine Commands

- (void)enableTimeMachineAuthorization:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    [self replyAfterRunning:kCPHelperPathTmutil
                  arguments:[CPHelperCommandRunner argumentsForTmutilEnable]
              failureMessage:@"Failed to enable Time Machine"
                      reply:reply];
}

- (void)disableTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    [self replyAfterRunning:kCPHelperPathTmutil
                  arguments:[CPHelperCommandRunner argumentsForTmutilDisable]
              failureMessage:@"Failed to disable Time Machine"
                      reply:reply];
}

- (void)startBackupTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    [self replyAfterRunning:kCPHelperPathTmutil
                  arguments:[CPHelperCommandRunner argumentsForTmutilStartBackup]
              failureMessage:@"Failed to start Time Machine backup"
                      reply:reply];
}

- (void)stopBackupTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    [self replyAfterRunning:kCPHelperPathTmutil
                  arguments:[CPHelperCommandRunner argumentsForTmutilStopBackup]
              failureMessage:@"Failed to stop Time Machine backup"
                      reply:reply];
}

#pragma mark - Internet Sharing Commands

- (void)enableInternetSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Internet Sharing is not supported on this version of macOS."]);
}

- (void)disableInternetSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Internet Sharing is not supported on this version of macOS."]);
}

#pragma mark - Firewall Commands

- (void)enableFirewallAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    // #124: app gates ToggleFirewall; do not let root helper toggle via XPC either.
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Firewall cannot be toggled on this version of macOS."]);
}

- (void)disableFirewallAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Firewall cannot be toggled on this version of macOS."]);
}

#pragma mark - Display Settings Commands

- (void)setDisplaySleepTime:(NSInteger)minutes authorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    if (![CPHelperCommandRunner isValidDisplaySleepMinutes:minutes]) {
        reply(NO, [self errorWithCode:EINVAL description:@"Invalid display sleep time"]);
        return;
    }

    [self replyAfterRunning:kCPHelperPathPmset
                  arguments:[CPHelperCommandRunner argumentsForDisplaySleepMinutes:minutes]
              failureMessage:@"Failed to set display sleep time"
                      reply:reply];
}

#pragma mark - Printer Sharing Commands

- (void)enablePrinterSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    // #124: app gates TogglePrinterSharing; do not let root helper toggle via XPC either.
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Printer Sharing cannot be toggled on this version of macOS."]);
}

- (void)disablePrinterSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Printer Sharing cannot be toggled on this version of macOS."]);
}

#pragma mark - File Sharing Commands

- (void)enableAFPFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"AFP file sharing is not supported on this version of macOS."]);
}

- (void)disableAFPFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"AFP file sharing is not supported on this version of macOS."]);
}

- (void)enableSMBFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    int retValue = [CPHelperCommandRunner runExecutable:kCPHelperPathLaunchctl
                                              arguments:[CPHelperCommandRunner argumentsForSMBEnable]];
    if (retValue == 0) {
        retValue = [CPHelperCommandRunner runExecutable:kCPHelperPathSMBSyncPreferences arguments:nil];
    }

    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable SMB File Sharing"]);
    }
}

- (void)disableSMBFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    int retValue = [CPHelperCommandRunner runExecutable:kCPHelperPathLaunchctl
                                              arguments:[CPHelperCommandRunner argumentsForSMBDisable]];
    if (retValue == 0) {
        retValue = [CPHelperCommandRunner runExecutable:kCPHelperPathSMBSyncPreferences arguments:nil];
    }

    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable SMB File Sharing"]);
    }
}

#pragma mark - TFTP Commands

- (void)enableTFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"TFTP sharing is not supported on this version of macOS."]);
}

- (void)disableTFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"TFTP sharing is not supported on this version of macOS."]);
}

#pragma mark - FTP Commands

- (void)enableFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"FTP sharing is not supported on this version of macOS."]);
}

- (void)disableFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"FTP sharing is not supported on this version of macOS."]);
}

#pragma mark - Web Sharing Commands

- (void)enableWebSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Web sharing is not supported on this version of macOS."]);
}

- (void)disableWebSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    (void)authData;
    reply(NO, [self errorWithCode:ENOTSUP description:@"Web sharing is not supported on this version of macOS."]);
}

#pragma mark - Remote Login Commands

- (void)enableRemoteLoginAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    // Prefer systemsetup over deprecated launchctl load of ssh.plist.
    [self replyAfterRunning:kCPHelperPathSystemsetup
                  arguments:[CPHelperCommandRunner argumentsForRemoteLoginEnable]
              failureMessage:@"Failed to enable Remote Login"
                      reply:reply];
}

- (void)disableRemoteLoginAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
        return;
    }

    [self replyAfterRunning:kCPHelperPathSystemsetup
                  arguments:[CPHelperCommandRunner argumentsForRemoteLoginDisable]
              failureMessage:@"Failed to disable Remote Login"
                      reply:reply];
}

@end
