//
//  CPLoginItemService.m
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPLoginItemService.h"

@implementation CPLoginItemService

+ (instancetype)sharedService
{
    static CPLoginItemService *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
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

- (SMAppService *)mainAppService
{
    return [SMAppService mainAppService];
}

- (SMAppServiceStatus)status
{
    return [[self mainAppService] status];
}

- (BOOL)isEnabled
{
    return ([self status] == SMAppServiceStatusEnabled);
}

- (BOOL)checkboxOn
{
    return [[self class] checkboxStateForStatus:[self status]];
}

- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error
{
    SMAppService *service = [self mainAppService];
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
            NSLog(@"Failed to register login item: %@", localError);
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

    if (service.status == SMAppServiceStatusNotRegistered) {
        return YES;
    }
    BOOL ok = [service unregisterAndReturnError:&localError];
    if (!ok) {
        NSLog(@"Failed to unregister login item: %@", localError);
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
        [SMAppService openSystemSettingsLoginItems];
    }
}

@end
