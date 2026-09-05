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
#import "ToggleNaturalScrollingAction.h"
#import "TimeMachineDestinationAction.h"

@interface ApplicabilityCharacterizationTests : XCTestCase
@end

@implementation ApplicabilityCharacterizationTests

- (void)testRetiredSharingActionsAreNotApplicableOnModernMacOS {
    // #22 gated FTP/TFTP/Web Sharing; asserts stay NO on macOS-15+.
    XCTAssertFalse([ToggleFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleTFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleWebSharingAction isActionApplicableToSystem]);
}

- (void)testScreenSaverPasswordActionIsNotApplicableOnSequoia {
    // #41: Lock Screen is no longer toggled via com.apple.screensaver askForPassword.
    XCTAssertFalse([ScreenSaverPasswordAction isActionApplicableToSystem]);
}

- (void)testScreenSaverPasswordWaitFlags {
    XCTAssertTrue([ScreenSaverPasswordAction shouldWaitForScreensaverExit]);
    XCTAssertTrue([ScreenSaverPasswordAction shouldWaitForScreenUnlock]);
}

- (void)testScreenSaverPasswordLimitedOptions {
    XCTAssertEqual([ScreenSaverPasswordAction limitedOptions].count, 2u);
}

- (void)testLegacyScreenSaverPasswordActionFailsClearly {
    ScreenSaverPasswordAction *action = [[ScreenSaverPasswordAction alloc] initWithOption:@YES];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"Lock Screen"].location != NSNotFound);
}

// #29: FireWireEvidenceSource now implements +isEvidenceSourceApplicableToSystem to gate
// FireWire on systems without a FireWire controller (Apple Silicon, modern Thunderbolt-only Macs).
// The implementation calls +isFireWireAvailable which queries IOKit for IOFireWireController.
// Direct unit testing requires linking FireWireEvidenceSource into the test target, which would
// pull the full evidence stack. The gate is verified by code review and integration smoke testing.

- (void)testToggleNaturalScrollingActionIsNotApplicableOnSequoia {
    // #47: Natural Scrolling toggle requires private CGS API; no reliable public alternative.
    XCTAssertFalse([ToggleNaturalScrollingAction isActionApplicableToSystem]);
}

- (void)testLegacyNaturalScrollingActionFailsClearly {
    ToggleNaturalScrollingAction *action = [[ToggleNaturalScrollingAction alloc] initWithOption:@YES];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"Natural Scrolling"].location != NSNotFound);
    XCTAssertTrue([error rangeOfString:@"System Settings"].location != NSNotFound);
}

- (void)testTimeMachineDestinationActionIsNotApplicableOnSequoia {
    // #44: Destination switching requires Tedium companion; archived / unavailable on Sequoia.
    XCTAssertFalse([TimeMachineDestinationAction isActionApplicableToSystem]);
}

- (void)testLegacyTimeMachineDestinationActionFailsClearly {
    TimeMachineDestinationAction *action = [[TimeMachineDestinationAction alloc] initWithOption:@"BackupDisk"];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"Time Machine Destination"].location != NSNotFound);
    XCTAssertTrue([error rangeOfString:@"Tedium"].location != NSNotFound);
}

- (void)testTimeMachineDestinationLimitedOptionsEmptyWhenGated {
    XCTAssertEqual([TimeMachineDestinationAction limitedOptions].count, 0u);
}

@end
