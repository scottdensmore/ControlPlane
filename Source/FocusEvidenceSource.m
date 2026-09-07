//
//  FocusEvidenceSource.m
//  ControlPlane
//
//  Reads Focus status via INFocusStatusCenter (public Intents API). Does not
//  write private Notification Center DND preferences (#113 / #34 B / #128).
//
//  Public API exposes only on/off (`isFocused`). Named Focus modes are not
//  readable; use Set Focus / Run Shortcut for those. There is no public
//  Focus-change notification on INFocusStatusCenter — we refresh on wake and
//  poll as a fallback (#128).
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <Intents/Intents.h>
#import <AppKit/AppKit.h>
#import "FocusEvidenceSource.h"
#import "DSLogger.h"
#import "NSTimer+Invalidation.h"

// No public Focus status change notification exists; keep a modest poll fallback.
static const NSTimeInterval kFocusPollIntervalSeconds = 30.0;

@implementation FocusEvidenceSource {
	BOOL focusOn;
	BOOL collected;
	NSTimer *pollTimer;
}

- (id)init {
	self = [super init];
	if (!self) {
		return nil;
	}
	focusOn = NO;
	collected = NO;
	return self;
}

- (id)initForMatchingTests {
	self = [super initForMatchingTests];
	if (!self) {
		return nil;
	}
	focusOn = NO;
	collected = NO;
	return self;
}

- (void)setFocusActiveForTesting:(BOOL)active {
	focusOn = active;
	collected = YES;
	[self setDataCollected:YES];
}

- (NSString *)description {
	return NSLocalizedString(
		@"Create rules based on whether Focus is currently on or off "
		@"(public API does not expose which named Focus mode is active — "
		@"use Set Focus / Run Shortcut for that).",
		@"");
}

- (void)refreshStatus {
	INFocusStatusCenter *center = [INFocusStatusCenter defaultCenter];
	INFocusStatusAuthorizationStatus auth = center.authorizationStatus;
	if (auth == INFocusStatusAuthorizationStatusNotDetermined) {
		[center requestAuthorizationWithCompletionHandler:^(INFocusStatusAuthorizationStatus status) {
			DSLog(@"Focus status authorization → %ld", (long)status);
		}];
	} else if (auth == INFocusStatusAuthorizationStatusDenied ||
		   auth == INFocusStatusAuthorizationStatusRestricted) {
		DSLog(@"Focus status authorization denied/restricted; rules will treat Focus as off until granted in System Settings → Privacy & Security → Focus.");
	}
	INFocusStatus *status = center.focusStatus;
	focusOn = status.isFocused != nil ? status.isFocused.boolValue : NO;
	collected = YES;
	[self setDataCollected:YES];
}

- (void)workspaceDidWake:(NSNotification *)note {
	(void)note;
	BOOL was = focusOn;
	[self refreshStatus];
	if (was != focusOn) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"evidenceSourceDataDidChange" object:nil];
	}
}

- (void)start {
	if (running) {
		return;
	}
	[self refreshStatus];

	NSNotificationCenter *wsnc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[wsnc addObserver:self
		 selector:@selector(workspaceDidWake:)
		     name:NSWorkspaceDidWakeNotification
		   object:nil];
	[wsnc addObserver:self
		 selector:@selector(workspaceDidWake:)
		     name:NSWorkspaceScreensDidWakeNotification
		   object:nil];

	// Fallback poll: INFocusStatusCenter has no public change notification (#128).
	pollTimer = [NSTimer scheduledTimerWithTimeInterval:kFocusPollIntervalSeconds
						     target:self
						   selector:@selector(timerFired:)
						   userInfo:nil
						    repeats:YES];
	running = YES;
}

- (void)timerFired:(NSTimer *)timer {
	(void)timer;
	BOOL was = focusOn;
	[self refreshStatus];
	if (was != focusOn) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"evidenceSourceDataDidChange" object:nil];
	}
}

- (void)stop {
	if (!running) {
		return;
	}
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	pollTimer = [pollTimer checkAndInvalidate];
	collected = NO;
	[self setDataCollected:NO];
	running = NO;
}

- (NSString *)name {
	return @"Focus";
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule {
	if (!collected) {
		return NO;
	}
	NSString *param = rule[@"parameter"];
	if ([param isEqualToString:@"Active"] || [param isEqualToString:@"on"]) {
		return focusOn;
	}
	if ([param isEqualToString:@"Inactive"] || [param isEqualToString:@"off"]) {
		return !focusOn;
	}
	return NO;
}

- (NSString *)getSuggestionLeadText:(NSString *)type {
	(void)type;
	return NSLocalizedString(@"Focus is", @"In rule-adding dialog");
}

- (NSArray *)getSuggestions {
	return @[
		@{ @"type": @"Focus", @"parameter": @"Active",
		   @"description": NSLocalizedString(@"Active (any Focus on)", @"") },
		@{ @"type": @"Focus", @"parameter": @"Inactive",
		   @"description": NSLocalizedString(@"Inactive (Focus off)", @"") },
	];
}

- (NSString *)friendlyName {
	return NSLocalizedString(@"Focus", @"");
}

+ (NSTimeInterval)pollIntervalSecondsForTesting {
	return kFocusPollIntervalSeconds;
}

@end
