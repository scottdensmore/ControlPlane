//
//  CPContextAppIntentBridge.m
//  ControlPlane
//

#import "CPContextAppIntentBridge.h"
#import "CPContextAppIntentTokens.h"
#import "CPController.h"

@implementation CPContextAppIntentBridge

+ (CPController *)runningController {
    id delegate = [NSApp delegate];
    if ([delegate isKindOfClass:[CPController class]]) {
        return (CPController *)delegate;
    }
    return nil;
}

+ (void)performOnMainThread:(dispatch_block_t)work {
    if ([NSThread isMainThread]) {
        work();
        return;
    }
    dispatch_sync(dispatch_get_main_queue(), work);
}

+ (NSArray<NSString *> *)orderedContextTokens {
    __block NSArray<NSString *> *tokens = @[];
    [self performOnMainThread:^{
        CPController *controller = [self runningController];
        if (controller != nil) {
            tokens = [controller contextNamesForForcedSwitchMenu];
        }
    }];
    return tokens ?: @[];
}

+ (BOOL)forceSwitchToContextNamed:(NSString *)name error:(NSError **)error {
    __block BOOL ok = NO;
    __block NSError *bridgeError = nil;
    [self performOnMainThread:^{
        CPController *controller = [self runningController];
        if (controller == nil) {
            bridgeError = [CPContextAppIntentTokens errorWithCode:CPContextAppIntentErrorNotReady
                                                      contextName:name];
            return;
        }
        ok = [controller forceSwitchToContextNamed:name error:&bridgeError];
    }];
    if (error != NULL) {
        *error = bridgeError;
    }
    return ok;
}

@end
