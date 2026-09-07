//
//  MonitorEvidenceSource.m
//  ControlPlane
//
//  Created by David Symonds on 2/07/07.
//

#import <AppKit/AppKit.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import "CPSystemInfo.h"
#import "MonitorEvidenceSource.h"

static NSString * const kCPDisplayCountRuleType = @"DisplayCount";
static NSString * const kCPDisplayArrangementRuleType = @"DisplayArrangement";

@implementation MonitorEvidenceSource

- (id)init
{
	if (!(self = [super init]))
		return nil;

	lock = [[NSLock alloc] init];
	monitors = [[NSMutableArray alloc] init];
	totalDisplayCount = -1;
	externalDisplayCount = -1;
	arrangementFingerprint = @"";

	return self;
}

- (id)initForMatchingTests
{
	if (!(self = [super initForMatchingTests]))
		return nil;

	lock = [[NSLock alloc] init];
	monitors = [[NSMutableArray alloc] init];
	totalDisplayCount = -1;
	externalDisplayCount = -1;
	arrangementFingerprint = @"";

	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:NSApplicationDidChangeScreenParametersNotification
	                                              object:nil];
}

- (void)start
{
	BOOL wasRunning = running;
	[super start];
	if (!running || wasRunning) {
		return;
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                       selector:@selector(screenParametersDidChange:)
	                                           name:NSApplicationDidChangeScreenParametersNotification
	                                         object:nil];
}

- (void)stop
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:NSApplicationDidChangeScreenParametersNotification
	                                              object:nil];
	[super stop];
}

- (void)screenParametersDidChange:(NSNotification *)notification
{
	(void)notification;
	[self doUpdate];
}

- (NSString *) description {
    return NSLocalizedString(@"Create rules based on attached monitors, display count, or arrangement.", @"");
}

+ (NSInteger)roundedDisplayValue:(id)value
{
	if (![value isKindOfClass:[NSNumber class]]) {
		return 0;
	}
	return (NSInteger)llround([value doubleValue]);
}

+ (NSString *)normalizedScaleString:(id)value
{
	double scale = 1.0;
	if ([value isKindOfClass:[NSNumber class]]) {
		scale = [value doubleValue];
	}
	if (scale <= 0) {
		scale = 1.0;
	}
	NSString *formatted = [NSString stringWithFormat:@"%.2f", scale];
	while ([formatted hasSuffix:@"0"]) {
		formatted = [formatted substringToIndex:formatted.length - 1];
	}
	if ([formatted hasSuffix:@"."]) {
		formatted = [formatted substringToIndex:formatted.length - 1];
	}
	return formatted.length > 0 ? formatted : @"1";
}

+ (NSArray *)normalizedDisplayDescriptors:(NSArray *)descriptors
{
	if (![descriptors isKindOfClass:[NSArray class]] || descriptors.count == 0) {
		return @[];
	}

	NSInteger minX = NSIntegerMax;
	NSInteger minY = NSIntegerMax;
	NSMutableArray *parsed = [NSMutableArray arrayWithCapacity:descriptors.count];
	for (id item in descriptors) {
		if (![item isKindOfClass:[NSDictionary class]]) {
			continue;
		}
		NSDictionary *display = (NSDictionary *)item;
		NSInteger x = [self roundedDisplayValue:display[@"x"]];
		NSInteger y = [self roundedDisplayValue:display[@"y"]];
		NSInteger width = [self roundedDisplayValue:display[@"width"]];
		NSInteger height = [self roundedDisplayValue:display[@"height"]];
		if (width <= 0 || height <= 0) {
			continue;
		}
		BOOL builtin = [display[@"builtin"] boolValue];
		NSString *scale = [self normalizedScaleString:display[@"scale"]];
		if (x < minX) {
			minX = x;
		}
		if (y < minY) {
			minY = y;
		}
		[parsed addObject:@{
			@"x": @(x),
			@"y": @(y),
			@"width": @(width),
			@"height": @(height),
			@"builtin": @(builtin),
			@"scale": scale,
		}];
	}

	if (parsed.count == 0) {
		return @[];
	}

	NSMutableArray *relative = [NSMutableArray arrayWithCapacity:parsed.count];
	for (NSDictionary *display in parsed) {
		[relative addObject:@{
			@"x": @([display[@"x"] integerValue] - minX),
			@"y": @([display[@"y"] integerValue] - minY),
			@"width": display[@"width"],
			@"height": display[@"height"],
			@"builtin": display[@"builtin"],
			@"scale": display[@"scale"],
		}];
	}

	[relative sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
		NSInteger ay = [a[@"y"] integerValue];
		NSInteger by = [b[@"y"] integerValue];
		if (ay != by) {
			return ay < by ? NSOrderedAscending : NSOrderedDescending;
		}
		NSInteger ax = [a[@"x"] integerValue];
		NSInteger bx = [b[@"x"] integerValue];
		if (ax != bx) {
			return ax < bx ? NSOrderedAscending : NSOrderedDescending;
		}
		BOOL aBuiltin = [a[@"builtin"] boolValue];
		BOOL bBuiltin = [b[@"builtin"] boolValue];
		if (aBuiltin != bBuiltin) {
			return aBuiltin ? NSOrderedAscending : NSOrderedDescending;
		}
		NSInteger aw = [a[@"width"] integerValue];
		NSInteger bw = [b[@"width"] integerValue];
		if (aw != bw) {
			return aw < bw ? NSOrderedAscending : NSOrderedDescending;
		}
		NSInteger ah = [a[@"height"] integerValue];
		NSInteger bh = [b[@"height"] integerValue];
		if (ah != bh) {
			return ah < bh ? NSOrderedAscending : NSOrderedDescending;
		}
		return [a[@"scale"] compare:b[@"scale"]];
	}];

	return relative;
}

+ (NSString *)arrangementFingerprintForDisplayDescriptors:(NSArray *)descriptors
{
	NSArray *normalized = [self normalizedDisplayDescriptors:descriptors];
	if (normalized.count == 0) {
		return @"";
	}

	NSMutableArray *parts = [NSMutableArray arrayWithCapacity:normalized.count];
	for (NSDictionary *display in normalized) {
		NSString *kind = [display[@"builtin"] boolValue] ? @"b" : @"e";
		[parts addObject:[NSString stringWithFormat:@"%@:%ld,%ld,%ldx%ld@%@",
		                  kind,
		                  (long)[display[@"x"] integerValue],
		                  (long)[display[@"y"] integerValue],
		                  (long)[display[@"width"] integerValue],
		                  (long)[display[@"height"] integerValue],
		                  display[@"scale"]]];
	}
	return [parts componentsJoinedByString:@"|"];
}

+ (NSInteger)externalCountForDescriptors:(NSArray *)descriptors
{
	NSInteger external = 0;
	for (id item in descriptors) {
		if (![item isKindOfClass:[NSDictionary class]]) {
			continue;
		}
		NSDictionary *display = (NSDictionary *)item;
		NSInteger width = [self roundedDisplayValue:display[@"width"]];
		NSInteger height = [self roundedDisplayValue:display[@"height"]];
		if (width <= 0 || height <= 0) {
			continue;
		}
		if (![display[@"builtin"] boolValue]) {
			external++;
		}
	}
	return external;
}

+ (BOOL)count:(NSInteger)count matchesOperator:(NSString *)op threshold:(NSInteger)threshold
{
	if ([op isEqualToString:@">="]) {
		return count >= threshold;
	}
	if ([op isEqualToString:@"<="]) {
		return count <= threshold;
	}
	if ([op isEqualToString:@"=="]) {
		return count == threshold;
	}
	if ([op isEqualToString:@">"]) {
		return count > threshold;
	}
	if ([op isEqualToString:@"<"]) {
		return count < threshold;
	}
	return NO;
}

+ (BOOL)displayCountParameter:(NSString *)parameter
                 matchesTotal:(NSInteger)total
                     external:(NSInteger)external
{
	if (![parameter isKindOfClass:[NSString class]] || parameter.length == 0) {
		return NO;
	}
	if (total < 0 || external < 0) {
		return NO;
	}

	NSString *trimmed = [parameter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *scope = @"total";
	NSString *expr = trimmed;
	if ([trimmed hasPrefix:@"external"]) {
		scope = @"external";
		expr = [[trimmed substringFromIndex:@"external".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	} else if ([trimmed hasPrefix:@"total"]) {
		expr = [[trimmed substringFromIndex:@"total".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}

	expr = [expr stringByReplacingOccurrencesOfString:@"\u2265" withString:@">="];
	expr = [expr stringByReplacingOccurrencesOfString:@"\u2264" withString:@"<="];

	NSString *op = nil;
	if ([expr hasPrefix:@">="]) {
		op = @">=";
	} else if ([expr hasPrefix:@"<="]) {
		op = @"<=";
	} else if ([expr hasPrefix:@"=="]) {
		op = @"==";
	} else if ([expr hasPrefix:@"="]) {
		op = @"==";
	} else if ([expr hasPrefix:@">"]) {
		op = @">";
	} else if ([expr hasPrefix:@"<"]) {
		op = @"<";
	} else {
		return NO;
	}

	NSString *numPart = [[expr substringFromIndex:op.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (numPart.length == 0) {
		return NO;
	}
	NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
	if ([numPart rangeOfCharacterFromSet:nonDigits].location != NSNotFound) {
		return NO;
	}

	NSInteger threshold = [numPart integerValue];
	NSInteger count = [scope isEqualToString:@"external"] ? external : total;
	return [self count:count matchesOperator:op threshold:threshold];
}

+ (NSNumber *)scaleForDisplayID:(CGDirectDisplayID)displayID
{
	// Public CGDisplay mode metrics. NSScreen is used only for the change notification
	// so this snapshot stays safe on the evidence polling queue.
	CGDisplayModeRef mode = CGDisplayCopyDisplayMode(displayID);
	if (!mode) {
		return @1;
	}
	size_t pixelWidth = CGDisplayModeGetPixelWidth(mode);
	size_t pointWidth = CGDisplayModeGetWidth(mode);
	CGDisplayModeRelease(mode);
	if (pointWidth == 0) {
		return @1;
	}
	return @((double)pixelWidth / (double)pointWidth);
}

+ (NSArray *)currentDisplayDescriptors
{
	CGDirectDisplayID displays[16];
	CGDisplayCount numDisplays = 0;
	if (CGGetActiveDisplayList(16, displays, &numDisplays) != kCGErrorSuccess) {
		return @[];
	}

	NSMutableArray *descriptors = [NSMutableArray arrayWithCapacity:numDisplays];
	for (CGDisplayCount i = 0; i < numDisplays; ++i) {
		CGDirectDisplayID displayID = displays[i];
		if (displayID == kCGNullDirectDisplay) {
			continue;
		}
		if (CGDisplayMirrorsDisplay(displayID) != kCGNullDirectDisplay) {
			continue;
		}
		CGRect bounds = CGDisplayBounds(displayID);
		[descriptors addObject:@{
			@"x": @(bounds.origin.x),
			@"y": @(bounds.origin.y),
			@"width": @(bounds.size.width),
			@"height": @(bounds.size.height),
			@"builtin": @(CGDisplayIsBuiltin(displayID)),
			@"scale": [self scaleForDisplayID:displayID],
		}];
	}
	return descriptors;
}

- (void)applyDisplayDescriptors:(NSArray *)descriptors monitorRecords:(NSArray *)monitorRecords
{
	NSArray *safeDescriptors = [descriptors isKindOfClass:[NSArray class]] ? descriptors : @[];
	NSArray *safeMonitors = [monitorRecords isKindOfClass:[NSArray class]] ? monitorRecords : @[];
	NSInteger total = 0;
	for (id item in safeDescriptors) {
		if ([item isKindOfClass:[NSDictionary class]]) {
			NSInteger width = [MonitorEvidenceSource roundedDisplayValue:((NSDictionary *)item)[@"width"]];
			NSInteger height = [MonitorEvidenceSource roundedDisplayValue:((NSDictionary *)item)[@"height"]];
			if (width > 0 && height > 0) {
				total++;
			}
		}
	}
	NSInteger external = [MonitorEvidenceSource externalCountForDescriptors:safeDescriptors];
	NSString *fingerprint = [MonitorEvidenceSource arrangementFingerprintForDisplayDescriptors:safeDescriptors];

	[lock lock];
	[monitors setArray:safeMonitors];
	totalDisplayCount = total;
	externalDisplayCount = external;
	arrangementFingerprint = fingerprint ?: @"";
	[self setDataCollected:(monitors.count > 0 || totalDisplayCount > 0)];
	[lock unlock];
}

- (void)setDisplayDescriptorsForTesting:(NSArray *)descriptors
{
	[self applyDisplayDescriptors:descriptors monitorRecords:[monitors copy]];
}

- (void)setMonitorsForTesting:(NSArray *)monitorRecords
{
	[lock lock];
	[monitors setArray:monitorRecords ?: @[]];
	[self setDataCollected:monitors.count > 0];
	[lock unlock];
}

- (NSArray *)collectMonitorRecords
{
	CGDirectDisplayID displays[8];
	CGDisplayCount numDisplays = 0;

	if (CGGetOnlineDisplayList(8, displays, &numDisplays) != kCGErrorSuccess) {
		NSLog(@"%@ >> CGGetOnlineDisplayList failed!", [self class]);
		return @[];
	}

#ifdef DEBUG_MODE
	NSLog(@"%@ ] %d display%s found.", [self class], numDisplays, numDisplays > 1 ? "s" : "");
#endif

	NSMutableArray *display_array = [NSMutableArray arrayWithCapacity:numDisplays];
	for (CGDisplayCount i = 0; i < numDisplays; ++i) {
		CGDirectDisplayID display_id = displays[i];
		if (CGDisplayMirrorsDisplay(display_id) != kCGNullDirectDisplay) {
			continue;
		}

		NSString *display_name = NSLocalizedString(@"(Unnamed display)", "String for unnamed monitors");
		io_service_t dev = [CPSystemInfo IOServicePortFromCGDisplayID:display_id];
		NSDictionary *dict = CFBridgingRelease(IODisplayCreateInfoDictionary(dev, kIODisplayOnlyPreferredName));
		if (!dict) {
			NSLog(@"%@ >> Couldn't get info about display with ID 0x%08x!", [self class], display_id);
			continue;
		}

		NSDictionary *subdict = [dict objectForKey:(NSString *) CFSTR(kDisplayProductName)];

        @try {
            if (subdict && ([subdict count] > 0))
                display_name = [[subdict allValues] objectAtIndex:0];
        }
        @catch (NSException *exception) {
            NSLog(@"failed to get monitor type/name");
        }

		NSNumber *display_serial = [dict objectForKey:(NSString *) CFSTR(kDisplayProductID)];

#ifdef DEBUG_MODE
		NSLog(@"%@ ] Display ID = 0x%08x: (%@) id = %@", [self class], display_id,
		      display_name, display_serial);
#endif
		[display_array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[display_serial stringValue], @"serial", display_name, @"name", nil]];
	}

	return display_array;
}

- (void)doUpdate
{
	NSArray *monitorRecords = [self collectMonitorRecords];
	NSArray *descriptors = [MonitorEvidenceSource currentDisplayDescriptors];
	[self applyDisplayDescriptors:descriptors monitorRecords:monitorRecords];
}

- (void)clearCollectedData
{
	[lock lock];
	[monitors removeAllObjects];
	totalDisplayCount = -1;
	externalDisplayCount = -1;
	arrangementFingerprint = @"";
	[self setDataCollected:NO];
	[lock unlock];
}

- (NSString *)name
{
	return @"Monitor";
}

- (NSArray *)typesOfRulesMatched
{
	return @[ @"Monitor", kCPDisplayCountRuleType, kCPDisplayArrangementRuleType ];
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule
{
	NSString *type = [rule valueForKey:@"type"];
	NSString *parameter = [rule valueForKey:@"parameter"];

	[lock lock];
	NSInteger total = totalDisplayCount;
	NSInteger external = externalDisplayCount;
	NSString *fingerprint = arrangementFingerprint ?: @"";
	NSArray *snapshot = [monitors copy];
	[lock unlock];

	if ([type isEqualToString:kCPDisplayCountRuleType]) {
		return [MonitorEvidenceSource displayCountParameter:parameter matchesTotal:total external:external];
	}
	if ([type isEqualToString:kCPDisplayArrangementRuleType]) {
		return fingerprint.length > 0 && [fingerprint isEqualToString:parameter];
	}

	BOOL match = NO;
	NSString *serial = parameter;
	for (NSDictionary *mon in snapshot) {
		if ([[mon valueForKey:@"serial"] isEqualToString:serial]) {
			match = YES;
			break;
		}
	}
	return match;
}

- (NSString *)getSuggestionLeadText:(NSString *)type
{
	if ([type isEqualToString:kCPDisplayCountRuleType]) {
		return NSLocalizedString(@"Display count is", @"In rule-adding dialog");
	}
	if ([type isEqualToString:kCPDisplayArrangementRuleType]) {
		return NSLocalizedString(@"Display arrangement is", @"In rule-adding dialog");
	}
	return NSLocalizedString(@"An attached monitor named", @"In rule-adding dialog");
}

- (NSArray *)countSuggestions
{
	return @[
		@{ @"type": kCPDisplayCountRuleType, @"parameter": @">=2",
		   @"description": NSLocalizedString(@"2 or more displays", @"At-desk display count") },
		@{ @"type": kCPDisplayCountRuleType, @"parameter": @">=3",
		   @"description": NSLocalizedString(@"3 or more displays", @"") },
		@{ @"type": kCPDisplayCountRuleType, @"parameter": @"==1",
		   @"description": NSLocalizedString(@"Exactly 1 display", @"") },
		@{ @"type": kCPDisplayCountRuleType, @"parameter": @"external>=1",
		   @"description": NSLocalizedString(@"1 or more external displays", @"") },
		@{ @"type": kCPDisplayCountRuleType, @"parameter": @"external>=2",
		   @"description": NSLocalizedString(@"2 or more external displays", @"") },
		@{ @"type": kCPDisplayCountRuleType, @"parameter": @"external==0",
		   @"description": NSLocalizedString(@"No external displays", @"") },
	];
}

- (NSArray *)getSuggestions
{
	NSMutableArray *arr = [NSMutableArray array];
	[arr addObjectsFromArray:[self countSuggestions]];

	[lock lock];
	NSString *fingerprint = arrangementFingerprint ?: @"";
	NSInteger total = totalDisplayCount;
	NSInteger external = externalDisplayCount;
	for (NSDictionary *mon in monitors) {
		NSString *name = [mon valueForKey:@"name"];
		NSString *serial = [mon valueForKey:@"serial"];
		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			@"Monitor", @"type",
			serial, @"parameter",
			name, @"description", nil]];
	}
	[lock unlock];

	if (fingerprint.length > 0) {
		NSString *description = [NSString stringWithFormat:
		                         NSLocalizedString(@"Current arrangement (%ld displays, %ld external)", @"Display arrangement suggestion"),
		                         (long)MAX(total, 0),
		                         (long)MAX(external, 0)];
		[arr addObject:@{
			@"type": kCPDisplayArrangementRuleType,
			@"parameter": fingerprint,
			@"description": description,
		}];
	}

	return arr;
}

- (NSString *) friendlyName {
    return NSLocalizedString(@"Attached Monitor", @"");
}
@end
