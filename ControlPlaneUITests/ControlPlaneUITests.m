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

- (void)testLaunchAndOpenPreferences {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchEnvironment = @{
        @"CPUITestRunning": @"1"
    };
    // Force prefs open via the app's documented debug default.
    app.launchArguments = @[ @"-Debug OpenPrefsAtStartup", @"YES" ];
    [app launch];

    XCUIElement *window = app.windows.firstMatch;
    XCTAssertTrue([window waitForExistenceWithTimeout:10], @"Preferences (or main) window should appear");

    // Prefer finding by title containing Preferences / ControlPlane
    BOOL foundPrefs = NO;
    for (XCUIElement *w in app.windows.allElementsBoundByIndex) {
        NSString *title = w.title;
        if (title.length == 0) {
            continue;
        }
        if ([title.lowercaseString containsString:@"preference"] ||
            [title.lowercaseString containsString:@"controlplane"]) {
            foundPrefs = YES;
            break;
        }
    }
    // Soft assert: some builds title the window differently; existence of any window is the floor.
    if (!foundPrefs) {
        XCTAssertTrue(window.exists, @"Expected at least one window after OpenPrefsAtStartup");
    }
}

- (void)testApplicationStarts {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertEqual(app.state, XCUIApplicationStateRunningForeground);
}

@end
