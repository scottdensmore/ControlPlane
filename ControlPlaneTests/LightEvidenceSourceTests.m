//
//  LightEvidenceSourceTests.m
//  ControlPlaneTests
//
//  #122: Light evidence gates cleanly when AppleLMUController is absent.
//

#import <XCTest/XCTest.h>
#import <IOKit/IOKitLib.h>
#import "LightEvidenceSource.h"

@interface LightEvidenceSourceTests : XCTestCase
@end

@implementation LightEvidenceSourceTests

- (BOOL)ioKitReportsAppleLMUController
{
	io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
	                                                   IOServiceMatching("AppleLMUController"));
	if (!service) {
		return NO;
	}
	IOObjectRelease(service);
	return YES;
}

- (void)testIsAppleLMUControllerAvailableMatchesIOKit
{
	XCTAssertEqual([LightEvidenceSource isAppleLMUControllerAvailable],
	               [self ioKitReportsAppleLMUController],
	               @"Availability probe must mirror IOKit AppleLMUController presence (#122)");
}

- (void)testApplicabilityMatchesAppleLMUControllerPresence
{
	XCTAssertEqual([LightEvidenceSource isEvidenceSourceApplicableToSystem],
	               [LightEvidenceSource isAppleLMUControllerAvailable],
	               @"Light must register only when AppleLMUController exists (#122)");
}

- (void)testUnavailablePathDoesNotCollectDataOrCrash
{
	LightEvidenceSource *source = [[LightEvidenceSource alloc] initForUnavailableLMUTesting];
	XCTAssertNotNil(source);

	XCTAssertNoThrow([source doUpdate]);
	XCTAssertFalse([source dataCollected],
	               @"Without an LMU connection, Light must not report collected data (#122)");
	XCTAssertEqualObjects([source valueForKey:@"currentLevel"],
	                      [LightEvidenceSource unavailableLevelDisplayString],
	                      @"Rule sheet should show Unavailable, not a broken empty/N/A percent (#122)");

	// Second poll stays quiet and stable (no mach_error spam path).
	XCTAssertNoThrow([source doUpdate]);
	XCTAssertFalse([source dataCollected]);
}

- (void)testUnavailableRulesDoNotMatch
{
	LightEvidenceSource *source = [[LightEvidenceSource alloc] initForUnavailableLMUTesting];
	[source doUpdate];
	NSDictionary *above = @{ @"parameter": @0.5 };
	NSDictionary *below = @{ @"parameter": @(-0.5) };
	XCTAssertFalse([source doesRuleMatch:above]);
	XCTAssertFalse([source doesRuleMatch:below],
	               @"Default level 0 must not match below-threshold rules when LMU is absent (#122)");
}

@end
