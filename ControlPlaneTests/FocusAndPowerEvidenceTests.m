//
//  FocusAndPowerEvidenceTests.m
//  ControlPlaneTests
//
//  #113 Focus + Low Power Mode / battery percent evidence (#34 B/C).
//

#import <XCTest/XCTest.h>
#import "Action.h"
#import "FocusEvidenceSource.h"
#import "PowerEvidenceSource.h"
#import "SetFocusAction.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface FocusAndPowerEvidenceTests : XCTestCase
@end

@implementation FocusAndPowerEvidenceTests

- (void)testSetFocusActionTypeRoundTrip {
	XCTAssertEqualObjects([Action typeForClass:[SetFocusAction class]], @"SetFocus");
	XCTAssertEqualObjects([Action classForType:@"SetFocus"], [SetFocusAction class]);

	SetFocusAction *action = (SetFocusAction *)[Action actionFromDictionary:@{
		@"type": @"SetFocus",
		@"parameter": @"Enable Work Focus",
		@"context": @"",
		@"when": @"Arrival",
		@"delay": @0,
		@"enabled": @YES
	}];
	XCTAssertNotNil(action);
	NSDictionary *roundTrip = [action dictionary];
	XCTAssertEqualObjects(roundTrip[@"type"], @"SetFocus");
	XCTAssertEqualObjects(roundTrip[@"parameter"], @"Enable Work Focus");
}

- (void)testSetFocusApplicabilityMatchesShortcutsCLI {
	BOOL applicable = [SetFocusAction isActionApplicableToSystem];
	BOOL cliPresent = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/usr/bin/shortcuts"];
	XCTAssertEqual(applicable, cliPresent);
}

- (void)testSetFocusHelpTextNamesGalleryPreset {
	NSString *help = [SetFocusAction helpText];
	XCTAssertTrue([help rangeOfString:@"Shortcuts recipe gallery" options:0].location != NSNotFound,
		      @"Prefs help for Set Focus must point at the gallery (#127)");
	XCTAssertTrue([help containsString:@"Enable Work Focus"],
		      @"Set Focus prefs help must suggest the gallery preset (#127)");
	XCTAssertTrue([help rangeOfString:@"Set Focus" options:0].location != NSNotFound);
}

- (void)testEmptySetFocusFailsWithoutInvokingCLI {
	SetFocusAction *action = [[SetFocusAction alloc] initWithDictionary:@{
		@"type": @"SetFocus",
		@"parameter": @"",
		@"context": @"",
		@"when": @"Arrival",
		@"delay": @0,
		@"enabled": @YES
	}];
	NSString *error = nil;
	XCTAssertFalse([action execute:&error]);
	XCTAssertNotNil(error);
}

- (void)testFocusEvidenceSuggestions {
	FocusEvidenceSource *src = [[FocusEvidenceSource alloc] initForMatchingTests];
	[src setFocusActiveForTesting:YES];
	XCTAssertTrue([src doesRuleMatch:@{ @"parameter": @"Active" }]);
	XCTAssertFalse([src doesRuleMatch:@{ @"parameter": @"Inactive" }]);
	NSArray *suggestions = [src getSuggestions];
	XCTAssertEqual(suggestions.count, 2u);
	XCTAssertEqualObjects(src.name, @"Focus");
}

- (void)testFocusPollIntervalIsFallbackNotAggressive {
	// #128: INFocusStatusCenter has no public change notification; poll is a fallback only.
	XCTAssertGreaterThanOrEqual([FocusEvidenceSource pollIntervalSecondsForTesting], 30.0);
}

- (void)testPowerExposesBatteryAndLowPowerRuleTypes {
	PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
	NSArray *types = [source typesOfRulesMatched];
	XCTAssertTrue([types containsObject:@"Power"]);
	XCTAssertTrue([types containsObject:@"BatteryLevel"]);
	XCTAssertTrue([types containsObject:@"LowPowerMode"]);

	[source setBatteryPercentForTesting:15 lowPowerMode:YES];
	NSDictionary *below = @{ @"type": @"BatteryLevel", @"parameter": @"below:20" };
	NSDictionary *above = @{ @"type": @"BatteryLevel", @"parameter": @"above:80" };
	NSDictionary *lpmOn = @{ @"type": @"LowPowerMode", @"parameter": @"on" };
	NSDictionary *lpmOff = @{ @"type": @"LowPowerMode", @"parameter": @"off" };
	XCTAssertTrue([source doesRuleMatch:below]);
	XCTAssertFalse([source doesRuleMatch:above]);
	XCTAssertTrue([source doesRuleMatch:lpmOn]);
	XCTAssertFalse([source doesRuleMatch:lpmOff]);
}

- (void)testInfoPlistDeclaresFocusStatusUsage {
	NSString *root = @CONTROLPLANE_SRCROOT;
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:
		[root stringByAppendingPathComponent:@"Info.plist"]];
	XCTAssertNotNil(plist[@"NSFocusStatusUsageDescription"]);
}

- (void)testHelpDocumentsFocusAndDoesNotAdvertiseGhostActions {
	NSString *root = @CONTROLPLANE_SRCROOT;
	NSString *actions = [NSString stringWithContentsOfFile:
		[root stringByAppendingPathComponent:@"Resources/ControlPlane Help/pages/actions.html"]
						 encoding:NSUTF8StringEncoding
						    error:nil];
	XCTAssertNotNil(actions);
	XCTAssertTrue([actions rangeOfString:@"Set Focus" options:NSCaseInsensitiveSearch].location != NSNotFound);
	XCTAssertFalse([actions containsString:@"Play iTunes Playlist"]);
	XCTAssertFalse([actions containsString:@"iChat/Messages Status"]);
	XCTAssertFalse([actions containsString:@"Change Mail IMAP"]);
	XCTAssertFalse([actions containsString:@"Change Mail SMTP"]);
}

- (void)testSparkleReleaseDocDocumentsEdDSAChecklist {
	NSString *root = @CONTROLPLANE_SRCROOT;
	NSString *doc = [NSString stringWithContentsOfFile:
		[root stringByAppendingPathComponent:@"docs/releasing.md"]
					     encoding:NSUTF8StringEncoding
						error:nil];
	XCTAssertNotNil(doc);
	XCTAssertTrue([doc containsString:@"SUPublicEDKey"]);
	XCTAssertTrue([doc containsString:@"generate_keys"]);
	XCTAssertTrue([doc containsString:@"Never commit"]);
}

@end
