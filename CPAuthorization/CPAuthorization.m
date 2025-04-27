//
//  CPAuthorization.m
//  ControlPlane
//
//  Created by Scott Densmore on 3/29/25.
//

#import "CPAuthorization.h"
#import "CPHelperToolProtocol.h"
#import "CPHelperCommon.h"

@implementation CPAuthorization

NSString * const kCommandKeyAuthRightName    = @"authRightName";
NSString * const kCommandKeyAuthRightDefault = @"authRightDefault";
NSString * const kCommandKeyAuthRightDesc    = @"authRightDescription";

+ (NSDictionary *)commandInfo
{
    static dispatch_once_t sOnceToken;
    static NSDictionary *  sCommandInfo;
    
    dispatch_once(&sOnceToken, ^{
        sCommandInfo = @{
            NSStringFromSelector(@selector(enableTimeMachineAuthorization:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableTMCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable Time Machine.",
                    @"prompt shown when user is required to authorize to enable time machine"
                )
            },
            NSStringFromSelector(@selector(disableTimeMachineAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableTMCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable Time Machine.",
                    @"prompt shown when user is required to authorize to disable time machine"
                )
            },
            NSStringFromSelector(@selector(startBackupTimeMachineAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperStartBackupTMCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to start a Time Machine backup.",
                    @"prompt shown when user is required to authorize to start a time machine backup"
                )
            },
            NSStringFromSelector(@selector(stopBackupTimeMachineAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperStopBackupTMCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to stop a Time Machine backup.",
                    @"prompt shown when user is required to authorize to stop a time machine backup"
                )
            },
            NSStringFromSelector(@selector(enableInternetSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableISCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable Internet Sharing.",
                    @"prompt shown when user is required to authorize to enable internet sharing"
                )
            },
            NSStringFromSelector(@selector(disableInternetSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableISCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable Internet Sharing.",
                    @"prompt shown when user is required to authorize to disable internet sharing"
                )
            },
            NSStringFromSelector(@selector(enableFirewallAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableFirewallCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable your Firewall.",
                    @"prompt shown when user is required to authorize to enable the firewall"
                )
            },
            NSStringFromSelector(@selector(disableFirewallAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableFirewallCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable your Firewall.",
                    @"prompt shown when user is required to authorize to disable the firewall"
                )
            },
            NSStringFromSelector(@selector(setDisplaySleepTime:authorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperSetDisplaySleepTimeCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to change the display sleep time.",
                    @"prompt shown when user is required to authorize to change the display sleep time"
                )
            },
            NSStringFromSelector(@selector(enablePrinterSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnablePrinterSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable Printer Sharing.",
                    @"prompt shown when user is required to authorize to enable printer sharing"
                )
            },
            NSStringFromSelector(@selector(disablePrinterSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisablePrinterSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable Printer Sharing.",
                    @"prompt shown when user is required to authorize to disable printer sharing"
                )
            },
            NSStringFromSelector(@selector(enableAFPFileSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableAFPFileSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable AFP File Sharing.",
                    @"prompt shown when user is required to authorize to enable afp file sharing"
                )
            },
            NSStringFromSelector(@selector(disableAFPFileSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableAFPFileSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleAuthenticateAsAdmin,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable AFP File Sharing.",
                    @"prompt shown when user is required to authorize to disalbe afp file sharing"
                )
            },
            NSStringFromSelector(@selector(enableSMBFileSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableSMBFileSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable SMB File Sharing.",
                    @"prompt shown when user is required to authorize to enable smnb file sharing"
                )
            },
            NSStringFromSelector(@selector(disableSMBFileSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableSMBFileSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable SMB File Sharing.",
                    @"prompt shown when user is required to authorize to disalbe smnb file sharing"
                )
            },
            NSStringFromSelector(@selector(enableTFTPAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableTMCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable TFTP.",
                    @"prompt shown when user is required to authorize to enable tftp"
                )
            },
            NSStringFromSelector(@selector(disableTFTPAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableTFTPCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable TFTP.",
                    @"prompt shown when user is required to authorize to disable tftp"
                )
            },
            NSStringFromSelector(@selector(enableFTPAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableFTPCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable FTP.",
                    @"prompt shown when user is required to authorize to enable ftp"
                )
            },
            NSStringFromSelector(@selector(disableFTPAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableFTPCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable FTP.",
                    @"prompt shown when user is required to authorize to disable ftp"
                )
            },
            NSStringFromSelector(@selector(enableWebSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableWebSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable Web Sharing.",
                    @"prompt shown when user is required to authorize to enable web sharing"
                )
            },
            NSStringFromSelector(@selector(disableWebSharingAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableWebSharingCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable Web Sharing.",
                    @"prompt shown when user is required to authorize to disable web sharing"
                )
            },
            NSStringFromSelector(@selector(enableRemoteLoginAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperEnableRemoteLoginCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to enable Remote Login.",
                    @"prompt shown when user is required to authorize to enable remote login"
                )
            },
            NSStringFromSelector(@selector(disableRemoteLoginAuthorizaiton:withReply:)) : @{
                kCommandKeyAuthRightName    : kCPHelperDisableRemoteLoginCommandAuthRightName,
                kCommandKeyAuthRightDefault : @kAuthorizationRuleClassAllow,
                kCommandKeyAuthRightDesc    : NSLocalizedString(
                    @"ControlPlane is trying to disable Remote Login.",
                    @"prompt shown when user is required to authorize to disable remote login"
                )
            }
        };
    });
    return sCommandInfo;
}

+ (NSString *)authorizationRightForCommand:(SEL)command
    // See comment in header.
{
    return [self commandInfo][NSStringFromSelector(command)][kCommandKeyAuthRightName];
}

+ (void)enumerateRightsUsingBlock:(void (^)(NSString * authRightName, id authRightDefault, NSString * authRightDesc))block
    // Calls the supplied block with information about each known authorization right..
{
    [self.commandInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        #pragma unused(key)
        #pragma unused(stop)
        NSDictionary *  commandDict;
        NSString *      authRightName;
        id              authRightDefault;
        NSString *      authRightDesc;
        
        // If any of the following asserts fire it's likely that you've got a bug
        // in sCommandInfo.
        
        commandDict = (NSDictionary *) obj;
        assert([commandDict isKindOfClass:[NSDictionary class]]);

        authRightName = [commandDict objectForKey:kCommandKeyAuthRightName];
        assert([authRightName isKindOfClass:[NSString class]]);

        authRightDefault = [commandDict objectForKey:kCommandKeyAuthRightDefault];
        assert(authRightDefault != nil);

        authRightDesc = [commandDict objectForKey:kCommandKeyAuthRightDesc];
        assert([authRightDesc isKindOfClass:[NSString class]]);

        block(authRightName, authRightDefault, authRightDesc);
    }];
}

+ (void)setupAuthorizationRights:(AuthorizationRef)authRef
{
    assert(authRef != NULL);
    [CPAuthorization enumerateRightsUsingBlock:^(NSString * authRightName, id authRightDefault, NSString * authRightDesc) {
        OSStatus    blockErr;
        
        // First get the right.  If we get back errAuthorizationDenied that means there's
        // no current definition, so we add our default one.
        
        blockErr = AuthorizationRightGet([authRightName UTF8String], NULL);
        if (blockErr == errAuthorizationDenied) {
            blockErr = AuthorizationRightSet(
                authRef,                                    // authRef
                [authRightName UTF8String],                 // rightName
                (__bridge CFTypeRef) authRightDefault,      // rightDefinition
                (__bridge CFStringRef) authRightDesc,       // descriptionKey
                NULL,                                       // bundle (NULL implies main bundle)
                CFSTR("Common")                             // localeTableName
            );
            assert(blockErr == errAuthorizationSuccess);
        } else {
            // A right already exists (err == noErr) or any other error occurs, we
            // assume that it has been set up in advance by the system administrator or
            // this is the second time we've run.  Either way, there's nothing more for
            // us to do.
        }
    }];
}

@end
