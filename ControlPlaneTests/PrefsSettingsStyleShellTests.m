//
//  PrefsSettingsStyleShellTests.m
//  ControlPlaneTests
//
//  Source-level checks for issue #100 Settings-style preferences shell.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface PrefsSettingsStyleShellTests : XCTestCase
@end

@implementation PrefsSettingsStyleShellTests

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

- (void)testSettingsShellUsesPreferenceStyleTabController {
	NSString *shell = [self contentsOfRelativePath:@"Source/CPPrefsSettingsShellController.m"];
	NSString *header = [self contentsOfRelativePath:@"Source/CPPrefsSettingsShellController.h"];

	XCTAssertTrue([header containsString:@"NSTabViewController"],
		      @"Shell should be an NSTabViewController subclass");
	XCTAssertTrue([shell containsString:@"NSTabViewControllerTabStyleToolbar"],
		      @"Shell must use preference-style toolbar tabs");
	XCTAssertTrue([shell containsString:@"prefs.settingsShell"],
		      @"Shell view needs an accessibility identifier");
	XCTAssertTrue([shell containsString:@"prefs.toolbar."],
		      @"Toolbar items should keep VoiceOver identifiers");
	XCTAssertTrue([shell containsString:@"respondsToSelector:@selector(setAccessibilityLabel:)"]
			  || [shell containsString:@"respondsToSelector:@selector(setAccessibilityIdentifier:)"],
		      @"Toolbar AX must probe NSToolbarItem before messaging (launch crash on some OS builds)");
}

- (void)testPrefsControllerHostsSettingsShellAndKeepsPanes {
	NSString *prefs = [self contentsOfRelativePath:@"Source/PrefsWindowController.m"];
	NSString *header = [self contentsOfRelativePath:@"Source/PrefsWindowController.h"];

	XCTAssertTrue([prefs containsString:@"CPPrefsSettingsShellController"],
		      @"PrefsWindowController must host the Settings-style shell");
	XCTAssertTrue([prefs containsString:@"configureWithPaneGroups"],
		      @"Existing pane groups should be embedded in the shell");
	XCTAssertTrue([prefs containsString:@"setContentViewController"],
		      @"Window should install the shell as contentViewController");

	for (NSString *pane in @[ @"General", @"Contexts", @"EvidenceSources", @"Rules", @"Actions", @"Advanced" ]) {
		NSString *token = [NSString stringWithFormat:@"@\"%@\"", pane];
		NSString *message = [NSString stringWithFormat:@"Pane %@ must remain registered", pane];
		XCTAssertTrue([prefs containsString:token], @"%@", message);
	}

	XCTAssertTrue([prefs containsString:@"prefs.tab."],
		      @"Pane VoiceOver identifiers from #31 must remain");
	XCTAssertTrue([prefs containsString:@"configureAgentApplicationMenu"],
		      @"Apple-menu comma shortcut wiring from #31 must remain");
	XCTAssertFalse([header containsString:@"NSToolbarDelegate"],
		       @"Hand-rolled toolbar delegate should be retired in favor of the shell");
}

- (void)testSpikeNotesDocumentChosenApproach {
	NSString *spike = [self contentsOfRelativePath:@"docs/prefs-settings-style-spike.md"];
	XCTAssertTrue([spike containsString:@"NSTabViewController"],
		      @"Spike notes should name the chosen AppKit approach");
	XCTAssertTrue([spike rangeOfString:@"SwiftUI" options:NSCaseInsensitiveSearch].location != NSNotFound,
		      @"Spike notes should record the SwiftUI alternative tradeoff");
	XCTAssertTrue([spike containsString:@"#100"] || [spike containsString:@"issue #100"],
		      @"Spike notes should link to the issue");
}

- (void)testMainMenuStillWiresCommaPreferencesShortcut {
	NSString *xib = [self contentsOfRelativePath:@"Resources/Base.lproj/MainMenu.xib"];
	XCTAssertTrue([xib containsString:@"keyEquivalent=\",\""],
		      @"Preferences must keep Command-comma");
	XCTAssertTrue([xib rangeOfString:@"runPreferences:"].location != NSNotFound);
}

@end
