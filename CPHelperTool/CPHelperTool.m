//
//  CPHelperTool.m
//  com.scottdensmore.CPHelperTool
//
//  Created by Scott Densmore on 3/29/25.
//

#import "CPHelperTool.h"
#import "CPHelperToolProtocol.h"
#import "CPHelperCommon.h"
#import "CPAuthorization.h"
#import "CPCommonConstants.h"

//NSString * const kHelperToolMachServiceName = @"com.scottdensmore.CPHelperTool";

@interface CPHelperTool () <NSXPCListenerDelegate, CPHelperToolProtocol>

@property (atomic, strong, readwrite) NSXPCListener *listener;

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;
- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command;

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
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    int retValue = 0;
    
    // Get system version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    
    // if macOS 10.7 or greater
    if ((major == 10 && minor >= 7) || major >= 11) {
        sprintf(command, "/usr/bin/tmutil enable");
        retValue = system(command);
    } else {
        sprintf(command, "/usr/bin/defaults write /Library/Preferences/com.apple.TimeMachine.plist %s %s %s", "AutoBackup", "-boolean", "TRUE");
        retValue = system(command);
    }
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable Time Machine"]);
    }
}

- (void)disableTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL success, NSError *error))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    int retValue = 0;
    
    // Get system version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    
    // if macOS 10.7 or greater
    if ((major == 10 && minor >= 7) || major >= 11) {
        sprintf(command, "/usr/bin/tmutil disable");
        retValue = system(command);
    } else {
        sprintf(command, "/usr/bin/defaults write /Library/Preferences/com.apple.TimeMachine.plist %s %s %s", "AutoBackup", "-boolean", "FALSE");
        retValue = system(command);
    }
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable Time Machine"]);
    }
}

- (void)startBackupTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    int retValue = 0;
    
    // Get system version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    
    // if macOS 10.7 or greater
    if ((major == 10 && minor >= 7) || major >= 11) {
        sprintf(command, "/usr/bin/tmutil startbackup");
        retValue = system(command);
    } else {
        sprintf(command, "/System/Library/CoreServices/backupd.bundle/Contents/Resources/backupd-helper &");
        retValue = system(command);
    }
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to start Time Machine backup"]);
    }
}

- (void)stopBackupTimeMachineAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    int retValue = 0;
    
    // Get system version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    
    // if macOS 10.7 or greater
    if ((major == 10 && minor >= 7) || major >= 11) {
        sprintf(command, "/usr/bin/tmutil stopbackup");
        retValue = system(command);
    } else {
        sprintf(command, "/usr/bin/killall backupd-helper");
        retValue = system(command);
    }
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to stop Time Machine backup"]);
    }
}

#pragma mark - Internet Sharing Commands

- (void)enableInternetSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable Internet Sharing"]);
    }
}

- (void)disableInternetSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.InternetSharing.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable Internet Sharing"]);
    }
}

#pragma mark - Firewall Commands

- (void)enableFirewallAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 1");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable Firewall"]);
    }
}

- (void)disableFirewallAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/usr/bin/defaults write /Library/Preferences/com.apple.alf globalstate -int 0");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable Firewall"]);
    }
}

#pragma mark - Display Settings Commands

- (void)setDisplaySleepTime:(NSInteger)minutes authorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/usr/bin/pmset -a displaysleep %ld", (long)minutes);
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to set display sleep time"]);
    }
}

#pragma mark - Printer Sharing Commands

- (void)enablePrinterSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/usr/sbin/cupsctl --share-printers");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable Printer Sharing"]);
    }
}

- (void)disablePrinterSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/usr/sbin/cupsctl --no-share-printers");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable Printer Sharing"]);
    }
}

#pragma mark - File Sharing Commands

- (void)enableAFPFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl load -F /System/Library/LaunchDaemons/%s.plist", [kCPHelperAFPServiceName UTF8String]);
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable AFP File Sharing"]);
    }
}

- (void)disableAFPFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl unload -F /System/Library/LaunchDaemons/%s.plist", [kCPHelperAFPServiceName UTF8String]);
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable AFP File Sharing"]);
    }
}

- (void)enableSMBFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char sync_command[256];
    char enable_command[256];
    int retValue = 0;
    
    // Get system version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    
    if ((major == 10 && minor >= 9) || major >= 11) {
        sprintf(enable_command, "/bin/launchctl load -F /System/Library/LaunchDaemons/%s.plist", [kCPHelperSMBDServiceName UTF8String]);
        sprintf(sync_command, "%s", [kCPHelperSMBSyncToolFilePathMavericks UTF8String]);
    } else {
        sprintf(enable_command, "/usr/bin/defaults write %s 'EnabledServices' -array 'disk'", [kCPHelperSMBPrefsFilePath UTF8String]);
        sprintf(sync_command, "%s", [kCPHelperSMBSyncToolFilePath UTF8String]);
    }
    
    retValue = system(enable_command);
    
    if (!retValue) {
        retValue = system(sync_command);
    }
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable SMB File Sharing"]);
    }
}

- (void)disableSMBFileSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char sync_command[256];
    char disable_command[256];
    int retValue = 0;
    
    // Get system version
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    
    if ((major == 10 && minor >= 9) || major >= 11) {
        sprintf(disable_command, "/bin/launchctl unload -F /System/Library/LaunchDaemons/%s.plist", [kCPHelperSMBDServiceName UTF8String]);
        sprintf(sync_command, "%s", [kCPHelperSMBSyncToolFilePathMavericks UTF8String]);
    } else {
        sprintf(disable_command, "/usr/bin/defaults delete %s 'EnabledServices'", [kCPHelperSMBPrefsFilePath UTF8String]);
        sprintf(sync_command, "%s", [kCPHelperSMBSyncToolFilePath UTF8String]);
    }
    
    retValue = system(disable_command);
    
    if (!retValue) {
        retValue = system(sync_command);
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
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl load -F /System/Library/LaunchDaemons/tftp.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable TFTP"]);
    }
}

- (void)disableTFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl unload -F /System/Library/LaunchDaemons/tftp.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable TFTP"]);
    }
}

#pragma mark - FTP Commands

- (void)enableFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl load -F /System/Library/LaunchDaemons/ftp.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable FTP"]);
    }
}

- (void)disableFTPAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl unload -F /System/Library/LaunchDaemons/ftp.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable FTP"]);
    }
}

#pragma mark - Web Sharing Commands

- (void)enableWebSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl load -F /System/Library/LaunchDaemons/org.apache.httpd.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable Web Sharing"]);
    }
}

- (void)disableWebSharingAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl unload -F /System/Library/LaunchDaemons/org.apache.httpd.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable Web Sharing"]);
    }
}

#pragma mark - Remote Login Commands

- (void)enableRemoteLoginAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl load -F /System/Library/LaunchDaemons/ssh.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to enable Remote Login"]);
    }
}

- (void)disableRemoteLoginAuthorizaiton:(NSData *)authData withReply:(void (^)(BOOL, NSError *))reply
{
    NSError *error;
    error = [self checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(NO, error);
    }
    
    char command[256];
    sprintf(command, "/bin/launchctl unload -F /System/Library/LaunchDaemons/ssh.plist");
    int retValue = system(command);
    
    if (retValue == 0) {
        reply(YES, nil);
    } else {
        reply(NO, [self errorWithCode:retValue description:@"Failed to disable Remote Login"]);
    }
}

@end
