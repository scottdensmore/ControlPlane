//
//  RemoteDesktopEvidenceSource.m
//  ControlPlane
//
//  Created by Dustin Rue on 4/19/15.
//
//

#import "DSLogger.h"
#import "RemoteDesktopEvidenceSource.h"

static const NSTimeInterval kRemoteDesktopNotifyGracePeriod = 90.0;

@interface RemoteDesktopEvidenceSource ()
@property (nonatomic, assign, readwrite) BOOL receivedRemoteDesktopNotify;
@property (nonatomic, assign) BOOL warnedAboutMissingNotify;
@end

@implementation RemoteDesktopEvidenceSource

- (id)init {
    self = [super init];
    if (self) {
        self.userConnected = NO;
        self.receivedRemoteDesktopNotify = NO;
        self.warnedAboutMissingNotify = NO;
    }
    return self;
}

- (id)initForMatchingTests {
    if (!(self = [super initForMatchingTests]))
        return nil;

    self.userConnected = NO;
    self.receivedRemoteDesktopNotify = NO;
    self.warnedAboutMissingNotify = NO;
    return self;
}

- (void)setUserConnectedForTesting:(BOOL)connected {
    self.userConnected = connected;
    self.receivedRemoteDesktopNotify = YES;
    [self setDataCollected:YES];
}

- (void)applyViewerNamesNotificationUserInfoForTesting:(NSDictionary *)userInfo {
    NSNotification *note = [NSNotification notificationWithName:@"com.apple.remotedesktop.viewerNames"
                                                         object:nil
                                                       userInfo:userInfo];
    [self doFullUpdate:note];
}

- (void)start {
    if (running) {
        return;
    }

    self.receivedRemoteDesktopNotify = NO;
    self.warnedAboutMissingNotify = NO;
    self.userConnected = NO;

    DSLog(@"RemoteDesktop evidence relies on the undocumented com.apple.remotedesktop.viewerNames distributed notification. If macOS stops posting it, Yes/No Remote Desktop rules will not update.");

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doFullUpdate:)
                                                 name:@"com.apple.remotedesktop.viewerNames"
                                               object:nil];

    [self performSelector:@selector(warnIfRemoteDesktopNotificationsNeverArrived)
               withObject:nil
               afterDelay:kRemoteDesktopNotifyGracePeriod];

    [self setDataCollected:YES];
    running = YES;
}

- (void)stop {
    if (!running) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(warnIfRemoteDesktopNotificationsNeverArrived)
                                               object:nil];

    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"com.apple.remotedesktop.viewerNames"
                                                  object:nil];
    
    [self setDataCollected:NO];
    
    running = NO;
}

- (void)doFullUpdate:(NSNotification *)notification {
    self.receivedRemoteDesktopNotify = YES;

    NSArray *connectedUsers = [[notification userInfo] valueForKey:@"ViewerNames"];
    if ([connectedUsers count] == 0) {
        self.userConnected = NO;
    }
    else {
        self.userConnected = YES;
    }
}

- (void)warnIfRemoteDesktopNotificationsNeverArrived {
    if (!running || self.receivedRemoteDesktopNotify || self.warnedAboutMissingNotify)
        return;

    self.warnedAboutMissingNotify = YES;
    DSLog(@"RemoteDesktop evidence has not received com.apple.remotedesktop.viewerNames since start; rules may stay at “No viewer connected.” Prefer other evidence if this persists after an OS update.");
}

- (NSString *)name {
    return @"RemoteDesktop";
}

- (NSString *)friendlyName {
    return NSLocalizedString(@"Remote Desktop", @"");
}


- (NSString *)description {
    return NSLocalizedString(@"Create rules based on whether someone is connected using Screen Sharing / Remote Desktop. This source listens for an undocumented macOS distributed notification and may stop updating if Apple changes that name.", @"");
}

- (NSArray *)getSuggestions {
    return @[
             @{ @"type": @"RemoteDesktop", @"parameter": @"Yes", @"description": NSLocalizedString(@"Yes", @"") },
             @{ @"type": @"RemoteDesktop", @"parameter": @"No",  @"description": NSLocalizedString(@"No", @"") },
             ];
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule {
    [self warnIfRemoteDesktopNotificationsNeverArrived];

    NSString *param = [rule objectForKey:@"parameter"];
    return (([param isEqualToString:@"Yes"] && self.userConnected) ||
            ([param isEqualToString:@"No"] && !self.userConnected));
}

- (NSString *)getSuggestionLeadText:(NSString *)type {
    return NSLocalizedString(@"Remote Desktop user is connected:", @"In rule-adding dialog");
}

@end
