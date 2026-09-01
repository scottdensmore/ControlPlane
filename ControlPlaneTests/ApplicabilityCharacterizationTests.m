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

@interface ApplicabilityCharacterizationTests : XCTestCase
@end

@implementation ApplicabilityCharacterizationTests

- (void)testRetiredSharingActionsAreNotApplicableOnModernMacOS {
    // #22 gated FTP/TFTP/Web Sharing; asserts stay NO on macOS-15+.
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

// FireWireEvidenceSource's isEvidenceSourceApplicableToSystem override is commented
// out in production (see #29). Characterizing the real IOKit gate belongs there;
// linking GenericLoopingEvidenceSource here would pull the full evidence stack.

@end
