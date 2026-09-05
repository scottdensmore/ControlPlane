//
//  ControlPlaneUITests.m
//  ControlPlaneUITests
//
//  User-journey smoke: launch the LSUIElement agent and open Preferences.
//

#import <XCTest/XCTest.h>

@interface ControlPlaneUITests : XCTestCase
@end

@implementation ControlPlaneUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (XCUIApplication *)launchWithPrefsOpen {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchEnvironment = @{ @"CPUITestRunning": @"1" };
    app.launchArguments = @[ @"-Debug OpenPrefsAtStartup", @"YES" ];
    [app launch];
    return app;
}

- (void)testLaunchAndOpenPreferences {
    XCUIApplication *app = [self launchWithPrefsOpen];

    XCUIElement *window = app.windows[@"prefs.window"];
    if (![window waitForExistenceWithTimeout:10]) {
        window = app.windows.firstMatch;
    }
    XCTAssertTrue(window.exists, @"Preferences window should appear after OpenPrefsAtStartup");
}

- (void)testToggleEnableNotificationsOff {
    XCUIApplication *app = [self launchWithPrefsOpen];

    XCUIElement *checkbox = app.checkBoxes[@"prefs.general.useNotifications"];
    XCTAssertTrue([checkbox waitForExistenceWithTimeout:10], @"Use Notifications checkbox should exist");

    if ([checkbox value] == nil || [[checkbox value] boolValue]) {
        [checkbox click];
    }

    XCTAssertFalse([[checkbox value] boolValue], @"Use Notifications should be off after toggle");
}

- (void)testNavigateToEvidenceSourcesTab {
    XCUIApplication *app = [self launchWithPrefsOpen];

    XCUIElement *evidenceTab = app.toolbars.buttons[@"Evidence Sources"];
    if (![evidenceTab waitForExistenceWithTimeout:5]) {
        evidenceTab = app.buttons[@"Evidence Sources"];
    }
    XCTAssertTrue(evidenceTab.exists, @"Evidence Sources toolbar item should exist");
    [evidenceTab click];

    XCUIElement *evidenceView = app.otherElements[@"prefs.tab.evidencesources"];
    XCTAssertTrue([evidenceView waitForExistenceWithTimeout:5], @"Evidence Sources tab view should appear");
}

@end
