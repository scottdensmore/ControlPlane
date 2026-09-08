//
//  CPHelperDaemonService.m
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPHelperDaemonService.h"

static NSString * const CPHelperDaemonPlistName = @"com.scottdensmore.CPHelperTool.plist";

@implementation CPHelperDaemonService

+ (instancetype)sharedService
{
    static CPHelperDaemonService *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (NSString *)launchDaemonPlistName
{
    return CPHelperDaemonPlistName;
}

+ (BOOL)checkboxStateForStatus:(SMAppServiceStatus)status
{
    switch (status) {
        case SMAppServiceStatusEnabled:
        case SMAppServiceStatusRequiresApproval:
            return YES;
        case SMAppServiceStatusNotRegistered:
        case SMAppServiceStatusNotFound:
        default:
            return NO;
    }
}

- (SMAppService *)daemonService
{
    return [SMAppService daemonServiceWithPlistName:[[self class] launchDaemonPlistName]];
}

- (SMAppServiceStatus)status
{
    return [[self daemonService] status];
}

- (BOOL)isEnabled
{
    return ([self status] == SMAppServiceStatusEnabled);
}

+ (BOOL)privilegedCommandMayConnectForStatus:(SMAppServiceStatus)status
{
    return status == SMAppServiceStatusEnabled;
}

- (BOOL)preparePrivilegedCommand
{
    if ([[self class] privilegedCommandMayConnectForStatus:[self status]]) {
        return YES;
    }
    // Existing Login Items approval. Do not register or call SMJobBless here.
    [[self class] openLoginItemsSettings];
    return NO;
}

+ (NSArray<NSString *> *)legacyBlessedInstallPaths
{
    return @[
        @"/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool",
        @"/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist",
    ];
}

+ (NSString *)legacyBlessedLaunchdBootoutTarget
{
    return @"system/com.scottdensmore.CPHelperTool";
}

- (BOOL)checkboxOn
{
    return [[self class] checkboxStateForStatus:[self status]];
}

- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error
{
    SMAppService *service = [self daemonService];
    NSError *localError = nil;

    if (enabled) {
        if (service.status == SMAppServiceStatusEnabled) {
            return YES;
        }
        if (service.status == SMAppServiceStatusRequiresApproval) {
            [[self class] openLoginItemsSettings];
            return YES;
        }
        BOOL ok = [service registerAndReturnError:&localError];
        if (!ok) {
            NSLog(@"Failed to register helper daemon: %@", localError);
            if (error != NULL) {
                *error = localError;
            }
            return NO;
        }
        if (service.status == SMAppServiceStatusRequiresApproval) {
            [[self class] openLoginItemsSettings];
        }
        return YES;
    }

    if (service.status == SMAppServiceStatusNotRegistered || service.status == SMAppServiceStatusNotFound) {
        return YES;
    }
    BOOL ok = [service unregisterAndReturnError:&localError];
    if (!ok) {
        NSLog(@"Failed to unregister helper daemon: %@", localError);
        if (error != NULL) {
            *error = localError;
        }
        return NO;
    }
    return YES;
}

+ (void)openLoginItemsSettings
{
    if (@available(macOS 13.0, *)) {
        void (^openSettings)(void) = ^{
            [SMAppService openSystemSettingsLoginItems];
        };
        // Privileged actions run on detached threads. Hop without sync so we cannot deadlock.
        if ([NSThread isMainThread]) {
            openSettings();
        } else {
            dispatch_async(dispatch_get_main_queue(), openSettings);
        }
    }
}

+ (NSString *)allowHelperCheckboxTitle
{
    return NSLocalizedString(@"Allow privileged helper",
                             @"General prefs checkbox to register the privileged helper");
}

+ (NSString *)allowHelperCheckboxToolTip
{
    return NSLocalizedString(@"Allow ControlPlane's privileged helper in Login Items & Extensions. Approval is required before the helper can run.",
                             @"Tooltip for the privileged helper checkbox");
}

+ (NSString *)registrationFailedAlertTitle
{
    return NSLocalizedString(@"Could Not Allow Privileged Helper",
                             @"Alert title when SMAppService daemon register fails");
}

+ (NSString *)registrationFailedAlertMessage
{
    return NSLocalizedString(@"Open System Settings → General → Login Items & Extensions and allow ControlPlane's privileged helper.",
                             @"Fallback guidance when helper daemon registration fails");
}

@end
