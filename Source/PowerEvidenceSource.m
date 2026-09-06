//
//  PowerEvidenceSource.m
//  ControlPlane
//
//  Created by Mark Wallis on 30/4/07.
//  Tweaks by David Symonds on 30/4/07.
//  Minor updates done by Vladimir Beloborodov (VladimirTechMan) on 25 Aug 2013.
//  Extended for Low Power Mode + battery percent thresholds (#113 / #34 C).
//

#import <IOKit/IOKitLib.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>
#import "PowerEvidenceSource.h"
#import "CPSystemInfo.h"


#pragma mark -

@implementation PowerEvidenceSource {
	NSString *status;
	NSInteger batteryPercent; // -1 when unknown / no battery
	BOOL lowPowerModeOn;
}

- (id)init {
    self = [super init];
	if (!self) {
		return nil;
    }
	batteryPercent = -1;
	lowPowerModeOn = NO;
	return self;
}

- (id)initForMatchingTests {
    self = [super initForMatchingTests];
    if (!self) {
        return nil;
    }
	batteryPercent = -1;
	lowPowerModeOn = NO;
    return self;
}

- (void)setPowerStatusForTesting:(NSString *)statusString {
    status = [statusString copy];
    [self setDataCollected:YES];
}

- (void)setBatteryPercentForTesting:(NSInteger)percent lowPowerMode:(BOOL)lpm {
	batteryPercent = percent;
	lowPowerModeOn = lpm;
	[self setDataCollected:YES];
}

- (void)dealloc {
}

- (NSString *)description {
    return NSLocalizedString(@"Create rules based on power source (adapter or battery), "
                             "battery charge percent thresholds, and Low Power Mode.", @"");
}

- (void)refreshLowPowerMode {
	if (@available(macOS 12.0, *)) {
		lowPowerModeOn = [[NSProcessInfo processInfo] isLowPowerModeEnabled];
	} else {
		lowPowerModeOn = NO;
	}
}

- (void)doFullUpdate:(NSNotification *)notification {
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	CFArrayRef list = IOPSCopyPowerSourcesList(blob);

	__block BOOL onBattery = YES;
	__block NSInteger bestPercent = -1;
    [(__bridge NSArray *) list enumerateObjectsUsingBlock:^(id source, NSUInteger idx, BOOL *stop) {
		NSDictionary *dict = (__bridge NSDictionary *) IOPSGetPowerSourceDescription(blob, (__bridge CFTypeRef) source);

		if ([dict[@kIOPSPowerSourceStateKey] isEqualToString:@kIOPSACPowerValue]) {
			onBattery = NO;
        }

		NSNumber *cur = dict[@kIOPSCurrentCapacityKey];
		NSNumber *max = dict[@kIOPSMaxCapacityKey];
		if ([cur isKindOfClass:[NSNumber class]] && [max isKindOfClass:[NSNumber class]] && max.integerValue > 0) {
			NSInteger pct = (NSInteger)llround((cur.doubleValue / max.doubleValue) * 100.0);
			if (pct > bestPercent) {
				bestPercent = pct;
			}
		}
    }];

    CFRelease(list);
	CFRelease(blob);

    status = (onBattery) ? (@"Battery") : (@"A/C");
	batteryPercent = bestPercent;
	[self refreshLowPowerMode];
	[self setDataCollected:YES];

    if (notification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"evidenceSourceDataDidChange" object:nil];
    }
}

- (void)lowPowerModeDidChange:(NSNotification *)notification {
	(void)notification;
	BOOL was = lowPowerModeOn;
	[self refreshLowPowerMode];
	if (was != lowPowerModeOn) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"evidenceSourceDataDidChange" object:nil];
	}
}

- (void)start {
	if (running) {
		return;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doFullUpdate:)
                                                 name:@"powerAdapterDidChangeNotification"
                                               object:nil];
	if (@available(macOS 12.0, *)) {
		[[NSNotificationCenter defaultCenter] addObserver:self
							 selector:@selector(lowPowerModeDidChange:)
							     name:NSProcessInfoPowerStateDidChangeNotification
							   object:nil];
	}

    [self doFullUpdate:nil];
	running = YES;
}

- (void)stop {
	if (!running) {
		return;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"powerAdapterDidChangeNotification"
                                                  object:nil];
	if (@available(macOS 12.0, *)) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
							    name:NSProcessInfoPowerStateDidChangeNotification
							  object:nil];
	}

	status = nil;
	batteryPercent = -1;
	lowPowerModeOn = NO;
	[self setDataCollected:NO];

	running = NO;
}

- (NSString *)name {
	return @"Power";
}

- (NSArray *)typesOfRulesMatched {
	return @[ @"Power", @"BatteryLevel", @"LowPowerMode" ];
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule {
	NSString *type = rule[@"type"];
	NSString *param = rule[@"parameter"];
	if ([type isEqualToString:@"LowPowerMode"]) {
		NSString *normalized = [param lowercaseString];
		if ([normalized isEqualToString:@"on"]) {
			return lowPowerModeOn;
		}
		if ([normalized isEqualToString:@"off"]) {
			return !lowPowerModeOn;
		}
		return NO;
	}
	if ([type isEqualToString:@"BatteryLevel"]) {
		if (batteryPercent < 0) {
			return NO;
		}
		// parameter formats: "below:20" / "above:80"
		NSArray *parts = [param componentsSeparatedByString:@":"];
		if (parts.count != 2) {
			return NO;
		}
		NSString *op = parts[0];
		NSInteger threshold = [parts[1] integerValue];
		if ([op isEqualToString:@"below"]) {
			return batteryPercent < threshold;
		}
		if ([op isEqualToString:@"above"]) {
			return batteryPercent > threshold;
		}
		return NO;
	}
	// Default Power type (A/C vs Battery)
	return status && [status isEqualToString:param];
}

- (NSString *)getSuggestionLeadText:(NSString *)type {
	if ([type isEqualToString:@"LowPowerMode"]) {
		return NSLocalizedString(@"Low Power Mode is", @"In rule-adding dialog");
	}
	if ([type isEqualToString:@"BatteryLevel"]) {
		return NSLocalizedString(@"Battery charge is", @"In rule-adding dialog");
	}
	return NSLocalizedString(@"Being powered by", @"In rule-adding dialog");
}

- (NSArray *)getSuggestions {
	return @[
        @{ @"type": @"Power", @"parameter": @"Battery", @"description": NSLocalizedString(@"Battery", @"") },
        @{ @"type": @"Power", @"parameter": @"A/C",     @"description": NSLocalizedString(@"Power Adapter", @"") },
	@{ @"type": @"BatteryLevel", @"parameter": @"below:20",
	   @"description": NSLocalizedString(@"Below 20%", @"") },
	@{ @"type": @"BatteryLevel", @"parameter": @"below:40",
	   @"description": NSLocalizedString(@"Below 40%", @"") },
	@{ @"type": @"BatteryLevel", @"parameter": @"above:80",
	   @"description": NSLocalizedString(@"Above 80%", @"") },
	@{ @"type": @"LowPowerMode", @"parameter": @"on",
	   @"description": NSLocalizedString(@"On", @"") },
	@{ @"type": @"LowPowerMode", @"parameter": @"off",
	   @"description": NSLocalizedString(@"Off", @"") },
    ];
}

- (void) goingToSleep:(id)arg {
    [self stop];
}

- (void) wakeFromSleep:(id)arg {
    [self start];
}

- (NSString *)friendlyName {
    return NSLocalizedString(@"Power / Battery", @"");
}

@end
