//
//  ControlPlaneUITests.m
//  ControlPlaneUITests
//
//  Deterministic Settings smoke (#202): launch-arg harness, no status-item clicks.
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
    XCUIApplication *existing = [[XCUIApplication alloc] init];
    if (existing.state != XCUIApplicationStateNotRunning) {
        [existing terminate];
        (void)[existing waitForState:XCUIApplicationStateNotRunning timeout:10];
    }

    // Cold attach to this LSUIElement agent under xcodebuild can throw
    // "does not have a process ID" once. Scope the expect to [app launch] only
    // so prefs.window / checkbox asserts are never masked.
    XCTExpectedFailureOptions *coldAttach = [[XCTExpectedFailureOptions alloc] init];
    coldAttach.strict = NO;
    coldAttach.issueMatcher = ^BOOL(XCTIssue *issue) {
        return [issue.compactDescription containsString:@"process ID"];
    };

    for (NSInteger attempt = 1; attempt <= 3; attempt++) {
        XCUIApplication *app = [[XCUIApplication alloc] init];
        app.launchEnvironment = @{ @"CPUITestRunning": @"1" };
        app.launchArguments = @[ @"-Debug OpenPrefsAtStartup", @"YES" ];

        if (attempt < 3) {
            XCTExpectFailureWithOptionsInBlock(
                @"Cold LSUIElement XCUITest attach may lack a process ID once",
                coldAttach,
                ^{ [app launch]; });
        } else {
            [app launch];
        }

        if ([app waitForState:XCUIApplicationStateRunningForeground timeout:30] ||
            [app waitForState:XCUIApplicationStateRunningBackground timeout:5]) {
            return app;
        }

        [app terminate];
        (void)[app waitForState:XCUIApplicationStateNotRunning timeout:10];
        [NSThread sleepForTimeInterval:1.0];
    }

    XCTFail(@"Failed to launch ControlPlane under UITest harness after retries");
    return nil;
}

- (void)testLaunchAndOpenPreferences {
    XCUIApplication *app = [self launchWithPrefsOpen];

    XCUIElement *window = app.windows[@"prefs.window"];
    XCTAssertTrue([window waitForExistenceWithTimeout:15],
                  @"Settings must appear via OpenPrefsAtStartup + prefs.window (no status-item clicks)");
}

- (void)testToggleEnableNotificationsOff {
    XCUIApplication *app = [self launchWithPrefsOpen];

    XCUIElement *window = app.windows[@"prefs.window"];
    XCTAssertTrue([window waitForExistenceWithTimeout:15], @"Settings window should appear");

    XCUIElement *checkbox = app.checkBoxes[@"prefs.general.useNotifications"];
    XCTAssertTrue([checkbox waitForExistenceWithTimeout:10], @"Use Notifications checkbox should exist");

    if ([checkbox value] == nil || [[checkbox value] boolValue]) {
        [checkbox click];
    }

    XCTAssertFalse([[checkbox value] boolValue], @"Use Notifications should be off after toggle");
}

@end
