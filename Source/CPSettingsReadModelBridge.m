//
//  CPSettingsReadModelBridge.m
//  ControlPlane
//

#import "CPSettingsReadModelBridge.h"
#import "CPSettingsReadModelTokens.h"
#import "CPController.h"
#import "Action.h"

@implementation CPSettingsReadModelBridge

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

+ (NSArray<NSDictionary *> *)orderedContextRows {
    __block NSArray<NSString *> *names = @[];
    [self performOnMainThread:^{
        CPController *controller = [self runningController];
        if (controller != nil) {
            names = [controller contextNamesForForcedSwitchMenu];
        }
    }];
    return [CPSettingsReadModelTokens contextRowsFromOrderedNames:names ?: @[]];
}

+ (NSArray<NSDictionary *> *)evidenceRows {
    __block NSArray<NSDictionary *> *descriptors = @[];
    [self performOnMainThread:^{
        CPController *controller = [self runningController];
        if (controller != nil) {
            descriptors = [controller evidenceSourceDescriptorsForSettings];
        }
    }];
    return [CPSettingsReadModelTokens evidenceRowsFromDescriptors:descriptors ?: @[]];
}

+ (NSArray<NSDictionary *> *)actionTypeRows {
    __block NSArray<NSDictionary *> *descriptors = @[];
    [self performOnMainThread:^{
        // ActionSetController's -init only builds its known class registry;
        // it does not depend on any nib outlet being wired, so instantiating
        // a throwaway instance here is safe and does not execute any action.
        ActionSetController *actionSet = [[ActionSetController alloc] init];
        NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
        for (NSString *type in [actionSet types]) {
            Class actionClass = [Action classForType:type];
            NSString *friendlyName = [actionClass respondsToSelector:@selector(friendlyName)]
                ? [actionClass friendlyName]
                : type;
            [rows addObject:@{ @"id": type ?: @"", @"name": friendlyName ?: (type ?: @"") }];
        }
        descriptors = rows;
    }];
    return [CPSettingsReadModelTokens actionTypeRowsFromDescriptors:descriptors ?: @[]];
}

@end
