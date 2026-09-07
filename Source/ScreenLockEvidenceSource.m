//
//  ScreenLockEvidenceSource.m
//  ControlPlane
//
//  Created by Roman Shevtsov on 12/12/15.
//
//

#import "DSLogger.h"
#import "ScreenLockEvidenceSource.h"

static const NSTimeInterval kScreenLockNotifyGracePeriod = 90.0;

@interface ScreenLockEvidenceSource ()
@property (nonatomic, assign, readwrite) BOOL receivedLockStateNotify;
@property (nonatomic, assign) BOOL warnedAboutMissingNotify;
@end

@implementation ScreenLockEvidenceSource

- (id) init {
    if (!(self = [super init]))
        return nil;

    return self;
}

- (id)initForMatchingTests {
    if (!(self = [super initForMatchingTests]))
        return nil;

    self.receivedLockStateNotify = NO;
    self.warnedAboutMissingNotify = NO;
    return self;
}

- (void)setScreenLockedForTesting:(BOOL)locked {
    self.screenIsLocked = locked;
    self.receivedLockStateNotify = YES;
    [self setDataCollected:YES];
}

- (NSString *) description {
    return NSLocalizedString(@"Create rules that are true when the system screen is locked or unlocked. This source listens for undocumented macOS distributed notifications and may stop updating if Apple changes those names.", @"");
}

- (void) doRealUpdate {
    [self setDataCollected:YES];
}

- (NSString*) name {
    return @"ScreenLock";
}

- (BOOL) doesRuleMatch: (NSDictionary*) rule {
    [self warnIfLockNotificationsNeverArrived];

    NSString *param = [rule objectForKey:@"parameter"];
    
    return (([param isEqualToString: @"lock"] && self.screenIsLocked) ||
            ([param isEqualToString: @"unlock"] && !self.screenIsLocked));
}

- (NSString*) getSuggestionLeadText: (NSString*) type {
    return NSLocalizedString(@"Screen lock is", @"In rule-adding dialog");
}

- (NSArray*) getSuggestions {
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"ScreenLock", @"type", @"lock", @"parameter",
             NSLocalizedString(@"Locked", @""), @"description", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"ScreenLock", @"type", @"unlock", @"parameter",
             NSLocalizedString(@"Unlocked", @""), @"description", nil],
            nil];
}

- (void) start {
    if (running)
        return;

    self.receivedLockStateNotify = NO;
    self.warnedAboutMissingNotify = NO;

    DSLog(@"ScreenLock evidence relies on undocumented distributed notifications (com.apple.screenIsLocked / com.apple.screenIsUnlocked). If macOS stops posting them, lock/unlock rules will not update.");

    [self doRealUpdate];

    [self performSelector:@selector(warnIfLockNotificationsNeverArrived)
               withObject:nil
               afterDelay:kScreenLockNotifyGracePeriod];

    running = YES;
}

- (void) stop {
    if (!running)
        return;

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(warnIfLockNotificationsNeverArrived)
                                               object:nil];

    [self setDataCollected:NO];
    
    running = NO;
}

- (NSString *) friendlyName {
    return NSLocalizedString(@"Screen Lock/Unlock", @"");
}

- (void)warnIfLockNotificationsNeverArrived {
    if (!running || self.receivedLockStateNotify || self.warnedAboutMissingNotify)
        return;

    self.warnedAboutMissingNotify = YES;
    DSLog(@"ScreenLock evidence has not received com.apple.screenIsLocked/Unlocked since start; rules may reflect the default unlocked state only. Prefer other evidence if this persists after an OS update.");
}

- (void) screenDidUnlock:(NSNotification *)notification {
    #ifdef DEBUG_MODE
        DSLog(@"screenDidUnlock: %@", [notification name]);
    #endif

    self.receivedLockStateNotify = YES;
    self.screenIsLocked = NO;
    [super screenDidUnlock:notification];
    [self doRealUpdate];
}

- (void) screenDidLock:(NSNotification *)notification {
    #ifdef DEBUG_MODE
        DSLog(@"screenDidLock: %@", [notification name]);
    #endif

    self.receivedLockStateNotify = YES;
    self.screenIsLocked = YES;
    [super screenDidLock:notification];
    [self doRealUpdate];
}

@end
