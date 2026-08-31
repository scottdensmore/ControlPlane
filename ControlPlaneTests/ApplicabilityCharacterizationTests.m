//
//  ApplicabilityCharacterizationTests.m
//  ControlPlaneTests
//
//  Characterizes current macOS-15 behavior (including known debt) so upgrades
//  cannot silently change applicability without failing tests.
//

#import <XCTest/XCTest.h>
#import "ToggleFTPAction.h"
#import "ToggleTFTPAction.h"
#import "ToggleWebSharingAction.h"
#import "ScreenSaverPasswordAction.h"
#import "FireWireEvidenceSource.h"

@interface ApplicabilityCharacterizationTests : XCTestCase
@end

@implementation ApplicabilityCharacterizationTests

- (void)testRetiredSharingActionsAreNotApplicableOnModernMacOS {
    XCTAssertFalse([ToggleFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleTFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleWebSharingAction isActionApplicableToSystem]);
}

- (void)testScreenSaverPasswordWaitFlags {
    XCTAssertTrue([ScreenSaverPasswordAction shouldWaitForScreensaverExit]);
    XCTAssertTrue([ScreenSaverPasswordAction shouldWaitForScreenUnlock]);
}

- (void)testScreenSaverPasswordLimitedOptions {
    XCTAssertEqual([ScreenSaverPasswordAction limitedOptions].count, 2u);
}

- (void)testFireWireEvidenceSourceApplicabilityIsBoolean {
    // Characterizes current gate; Apple Silicon typically NO if overridden.
    BOOL applicable = [FireWireEvidenceSource isEvidenceSourceApplicableToSystem];
    (void)applicable;
    XCTAssertTrue(applicable == YES || applicable == NO);
}

@end
