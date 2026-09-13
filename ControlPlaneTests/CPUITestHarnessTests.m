//
//  CPUITestHarnessTests.m
//  ControlPlaneTests
//
//  Source-level contract for issue #202: open Settings in UITests without
//  menu-bar pixel clicks.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPUITestHarnessTests : XCTestCase
@end

@implementation CPUITestHarnessTests

- (NSString *)srcRoot {
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
	return root;
}

- (NSString *)contentsOfRelativePath:(NSString *)relative {
	NSString *path = [[self srcRoot] stringByAppendingPathComponent:relative];
	NSError *error = nil;
	NSString *text = [NSString stringWithContentsOfFile:path
						   encoding:NSUTF8StringEncoding
						      error:&error];
	XCTAssertNil(error, @"Failed reading %@: %@", path, error);
	XCTAssertNotNil(text);
	return text;
}

- (void)testOpenPrefsAtStartupGoesThroughRunPreferences {
	NSString *controller = [self contentsOfRelativePath:@"Source/CPController.m"];
	XCTAssertTrue([controller containsString:@"Debug OpenPrefsAtStartup"],
		      @"Harness launch arg maps to Debug OpenPrefsAtStartup");

	NSRange key = [controller rangeOfString:@"Debug OpenPrefsAtStartup"];
	XCTAssertTrue(key.location != NSNotFound);
	// Look at the startup open block (second mention is typically the runtime check).
	NSRange search = NSMakeRange(key.location, controller.length - key.location);
	NSRange runtime = [controller rangeOfString:@"boolForKey:@\"Debug OpenPrefsAtStartup\""
					    options:0
					      range:search];
	XCTAssertTrue(runtime.location != NSNotFound,
		      @"Startup must read Debug OpenPrefsAtStartup from defaults");

	NSString *tail = [controller substringFromIndex:runtime.location];
	// Bound the OpenPrefsAtStartup block (avoid scraping to an unrelated early `}`).
	NSUInteger windowLen = MIN((NSUInteger)500, tail.length);
	NSString *block = [tail substringToIndex:windowLen];
	XCTAssertTrue([block containsString:@"runPreferences:"],
		      @"OpenPrefsAtStartup must open Settings via runPreferences: (not status-item clicks)");
}

- (void)testUITestEnvSkipsNotificationAuthorizationPrompts {
	NSString *notifications = [self contentsOfRelativePath:@"Source/CPNotifications.m"];
	XCTAssertTrue([notifications containsString:@"CPUITestRunning"],
		      @"Notification auth must no-op under CPUITestRunning so Settings can appear");
	NSRange env = [notifications rangeOfString:@"CPUITestRunning"];
	XCTAssertTrue(env.location != NSNotFound);
	NSString *after = [notifications substringFromIndex:env.location];
	NSRange un = [after rangeOfString:@"UNUserNotificationCenter"];
	XCTAssertTrue(un.location != NSNotFound,
		      @"Expected UNUserNotificationCenter path after the harness guard");
	// Early return for the harness must appear before talking to the notification center.
	NSRange ret = [after rangeOfString:@"return;"];
	XCTAssertTrue(ret.location != NSNotFound && ret.location < un.location,
		      @"CPUITestRunning must return before UNUserNotificationCenter authorization");
}

- (void)testUITestEnvUsesRegularActivationPolicyForXCUITestAttach {
	NSString *main = [self contentsOfRelativePath:@"Source/main.m"];
	XCTAssertTrue([main containsString:@"CPUITestRunning"],
		      @"main must detect CPUITestRunning before NSApplicationMain");
	XCTAssertTrue([main containsString:@"NSApplicationActivationPolicyRegular"],
		      @"LSUIElement agents need Regular activation policy so XCUITest can attach");
}

- (void)testStableAccessibilityIdentifiersForSettingsHarness {
	NSString *prefs = [self contentsOfRelativePath:@"Source/PrefsWindowController.m"];
	NSString *contexts = [self contentsOfRelativePath:@"Source/ContextsDataSource.m"];
	NSString *shell = [self contentsOfRelativePath:@"Source/CPPrefsSettingsShellController.m"];

	XCTAssertTrue([prefs containsString:@"prefs.window"],
		      @"Settings window needs prefs.window AX id");
	XCTAssertTrue([contexts containsString:@"prefs.general.useNotifications"],
		      @"General notifications checkbox needs a stable AX id");
	XCTAssertTrue([shell containsString:@"prefs.settingsShell"],
		      @"Settings shell needs prefs.settingsShell AX id");
	XCTAssertTrue([shell containsString:@"prefs.toolbar."],
		      @"Toolbar tabs need prefs.toolbar.* AX ids");
}

- (void)testUITestSmokeUsesLaunchArgNotStatusItemGeometry {
	NSString *uitest = [self contentsOfRelativePath:@"ControlPlaneUITests/ControlPlaneUITests.m"];
	XCTAssertTrue([uitest containsString:@"CPUITestRunning"],
		      @"UITests must set CPUITestRunning");
	XCTAssertTrue([uitest containsString:@"Debug OpenPrefsAtStartup"],
		      @"UITests must open Settings via Debug OpenPrefsAtStartup");
	XCTAssertTrue([uitest containsString:@"prefs.window"],
		      @"Smoke must locate Settings by prefs.window");
	XCTAssertTrue([uitest containsString:@"ForceContextAtStartup"] ||
			  [uitest containsString:@"UITestForceContext"],
		      @"UITests should exercise the Force Context hook (#244)");
	XCTAssertFalse([uitest containsString:@"coordinateWithNormalizedOffset"],
		       @"Do not open Settings via menu-bar pixel/geometry clicks");
	XCTAssertFalse([uitest containsString:@"status.item.controlplane"],
		       @"Status-item clicks remain out of scope (use Force Context hooks for #206)");
}

- (void)testTestingDocsDocumentUITestHarness {
	NSString *docs = [self contentsOfRelativePath:@"docs/TESTING.md"];
	XCTAssertTrue([docs containsString:@"## UITest harness"],
		      @"docs/TESTING.md must document the UITest harness");
	XCTAssertTrue([docs containsString:@"CPUITestRunning"],
		      @"Harness docs must name CPUITestRunning");
	XCTAssertTrue([docs containsString:@"OpenPrefsAtStartup"],
		      @"Harness docs must name OpenPrefsAtStartup");
	XCTAssertTrue([docs containsString:@"ForceContextAtStartup"] ||
			  [docs containsString:@"UITestForceContext"],
		      @"Harness docs must cover the Force Context hook (#244)");
	XCTAssertTrue([docs containsString:@"#206"] || [docs containsString:@"issue 206"],
		      @"Harness docs should point Force Context journeys at #206");
	XCTAssertTrue([docs containsString:@"PosixSpawn"],
		      @"Harness docs must note PosixSpawn Test launcher (attach/PID)");
}

- (void)testSharedSchemeUsesPosixSpawnForUITestAttach {
	NSString *scheme = [self contentsOfRelativePath:
		@"ControlPlane.xcodeproj/xcshareddata/xcschemes/ControlPlane.xcscheme"];
	NSRange testAction = [scheme rangeOfString:@"<TestAction"];
	NSRange launchAction = [scheme rangeOfString:@"<LaunchAction"];
	XCTAssertTrue(testAction.location != NSNotFound && launchAction.location != NSNotFound);
	XCTAssertTrue(testAction.location < launchAction.location);
	NSString *testSection = [scheme substringWithRange:NSMakeRange(testAction.location,
								       launchAction.location - testAction.location)];
	XCTAssertTrue([testSection containsString:@"Xcode.IDEFoundation.Launcher.PosixSpawn"],
		      @"Test action must use PosixSpawn so UITests get a process ID");
	XCTAssertFalse([testSection containsString:@"Xcode.DebuggerFoundation.Launcher.LLDB"],
		       @"LLDB on the Test action regresses UITest attach for this LSUIElement agent");
}

@end
