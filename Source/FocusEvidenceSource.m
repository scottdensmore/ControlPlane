//
//  FocusEvidenceSource.m
//  ControlPlane
//
//  Reads Focus status via INFocusStatusCenter (public Intents API). Does not
//  write private Notification Center DND preferences (#113 / #34 B).
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <Intents/Intents.h>
#import "FocusEvidenceSource.h"
#import "DSLogger.h"
#import "NSTimer+Invalidation.h"

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
	return NSLocalizedString(@"Create rules based on whether Focus (formerly Do Not Disturb) is currently on.", @"");
}

- (void)refreshStatus {
	INFocusStatusCenter *center = [INFocusStatusCenter defaultCenter];
	INFocusStatusAuthorizationStatus auth = center.authorizationStatus;
	if (auth == INFocusStatusAuthorizationStatusNotDetermined) {
		[center requestAuthorizationWithCompletionHandler:^(INFocusStatusAuthorizationStatus status) {
			DSLog(@"Focus status authorization → %ld", (long)status);
		}];
	}
	INFocusStatus *status = center.focusStatus;
	focusOn = status.isFocused != nil ? status.isFocused.boolValue : NO;
	collected = YES;
	[self setDataCollected:YES];
}

- (void)start {
	if (running) {
		return;
	}
	[self refreshStatus];
	// Poll periodically; Focus change notifications are not always delivered to agents.
	pollTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
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
		   @"description": NSLocalizedString(@"Active", @"") },
		@{ @"type": @"Focus", @"parameter": @"Inactive",
		   @"description": NSLocalizedString(@"Inactive", @"") },
	];
}

- (NSString *)friendlyName {
	return NSLocalizedString(@"Focus", @"");
}

@end
