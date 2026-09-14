//
//  ControlPlaneUITests.m
//  ControlPlaneUITests
//
//  Deterministic Settings smoke (#202) + Force Context hook smoke (#244):
//  launch-arg / notification harness, no status-item clicks.
//

#import <XCTest/XCTest.h>

@interface ControlPlaneUITests : XCTestCase
@end

@implementation ControlPlaneUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (XCUIApplication *)launchWithArguments:(NSArray<NSString *> *)arguments {
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
        app.launchArguments = arguments;

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

- (XCUIApplication *)launchWithPrefsOpen {
    return [self launchWithArguments:@[ @"-Debug OpenPrefsAtStartup", @"YES" ]];
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

/// #244: Force Context launch arg + distributed notification must not hang/crash the
/// Settings harness. Full seed→force→assert journey is #206.
- (void)testForceContextHookDoesNotBreakSettingsHarness {
    XCUIApplication *app = [self launchWithArguments:@[
        @"-Debug OpenPrefsAtStartup", @"YES",
        @"-Debug ForceContextAtStartup", @"__CPUITestMissingContext__",
    ]];

    XCUIElement *window = app.windows[@"prefs.window"];
    XCTAssertTrue([window waitForExistenceWithTimeout:15],
                  @"ForceContextAtStartup (missing token) must not block OpenPrefsAtStartup");

    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:@"com.scottdensmore.ControlPlane.UITestForceContext"
                      object:nil
                    userInfo:@{ @"name": @"__CPUITestMissingContext__" }
          deliverImmediately:YES];

    // Give the main-queue handler a beat; Settings must remain reachable.
    [NSThread sleepForTimeInterval:0.5];
    XCTAssertTrue(window.exists,
                  @"UITestForceContext notification must not tear down Settings");
}

/// #229: minimal create-context journey through the SwiftUI Contexts pane —
/// switch to the Contexts tab, add a context via the name sheet, and confirm
/// it appears in the list. No status-item clicks; name is unique per run.
- (void)testCreateContextViaContextsPane {
    XCUIApplication *app = [self launchWithPrefsOpen];

    XCUIElement *window = app.windows[@"prefs.window"];
    XCTAssertTrue([window waitForExistenceWithTimeout:15], @"Settings window should appear");

    XCUIElement *toolbarContexts = app.toolbars.buttons[@"prefs.toolbar.contexts"];
    XCTAssertTrue([toolbarContexts waitForExistenceWithTimeout:10],
                  @"Contexts toolbar item should exist");
    [toolbarContexts click];

    XCUIElement *add = window.buttons[@"prefs.contexts.add"];
    XCTAssertTrue([add waitForExistenceWithTimeout:10], @"Add Context button should exist");
    [add click];

    NSString *name = [NSString stringWithFormat:@"UITest Context %@", NSUUID.UUID.UUIDString];
    XCUIElement *nameField = app.textFields[@"prefs.contexts.sheet.name"];
    XCTAssertTrue([nameField waitForExistenceWithTimeout:10], @"Context name sheet field should exist");
    [nameField click];

    // The sheet pre-fills a default name ("New context") and selects it; typing
    // replaces the selection rather than appending.
    [nameField typeText:name];

    XCUIElement *ok = app.buttons[@"prefs.contexts.sheet.confirm"];
    XCTAssertTrue([ok waitForExistenceWithTimeout:5], @"Context name sheet confirm button should exist");
    [ok click];

    XCTAssertTrue([window.staticTexts[name] waitForExistenceWithTimeout:10],
                  @"Created context name must appear in the Contexts list");
}

@end
