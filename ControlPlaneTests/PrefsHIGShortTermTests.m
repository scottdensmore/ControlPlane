//
//  PrefsHIGShortTermTests.m
//  ControlPlaneTests
//
//  Source-level checks for issue #31 short-term prefs HIG slice:
//  accessibility labels, agent menu shortcuts, standard About, Help accuracy.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface PrefsHIGShortTermTests : XCTestCase
@end

@implementation PrefsHIGShortTermTests

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

- (void)testMainMenuAppleMenuHasStandardShortcuts {
	NSString *xib = [self contentsOfRelativePath:@"Resources/Base.lproj/MainMenu.xib"];

	XCTAssertTrue([xib containsString:@"keyEquivalent=\",\""],
		      @"Settings must use ⌘,");
	XCTAssertTrue([xib containsString:@"keyEquivalent=\"q\""],
		      @"Quit must use ⌘Q");
	XCTAssertTrue([xib containsString:@"keyEquivalent=\"h\""],
		      @"Hide must use ⌘H");

	XCTAssertFalse([xib containsString:@"MarcoPolo"],
		       @"Apple menu must not still say MarcoPolo");
	XCTAssertTrue([xib containsString:@"Hide ControlPlane"],
		      @"Hide item should name ControlPlane");
	XCTAssertTrue([xib containsString:@"Quit ControlPlane"],
		      @"Quit item should name ControlPlane");

	// Wired actions (XIB and/or runtime configureAgentApplicationMenu)
	XCTAssertTrue([xib rangeOfString:@"runPreferences:"].location != NSNotFound);
	XCTAssertTrue([xib rangeOfString:@"runAbout:"].location != NSNotFound);
	XCTAssertTrue([xib rangeOfString:@"selector=\"terminate:\""].location != NSNotFound);
	XCTAssertTrue([xib rangeOfString:@"selector=\"hide:\""].location != NSNotFound);
	XCTAssertTrue([xib containsString:@"Settings..."],
		      @"Menu item should say Settings (HIG)");
	XCTAssertFalse([xib containsString:@"Preferences..."],
		       @"Menu item must not still say Preferences...");
}

- (void)testPrefsControllerUsesSettingsNamingAndTitle {
	NSString *prefs = [self contentsOfRelativePath:@"Source/PrefsWindowController.m"];
	XCTAssertTrue([prefs containsString:@"NSLocalizedString(@\"Settings\""],
		      @"Window title should use localized Settings");
	XCTAssertTrue([prefs containsString:@"ControlPlane Settings"] ||
			  [prefs containsString:@"@\"Settings\""],
		      @"VoiceOver / title should prefer Settings naming");
	XCTAssertFalse([prefs containsString:@"ControlPlane - "],
		       @"Do not use ControlPlane - {pane} window titles");
}

- (void)testLocalePrefsWindowsAreNSWindowNotNSPanel {
	NSArray<NSString *> *locales = @[ @"de", @"fr", @"it", @"da-DK", @"pt-BR", @"pt-PT" ];
	for (NSString *locale in locales) {
		NSString *rel = [NSString stringWithFormat:@"Resources/%@.lproj/MainMenu.xib", locale];
		NSString *xib = [self contentsOfRelativePath:rel];
		// Prefs window id 910 must not declare customClass NSPanel (Base uses NSWindow).
		NSRange prefsWin = [xib rangeOfString:@"id=\"910\" userLabel=\"PrefsWindow\""];
		XCTAssertTrue(prefsWin.location != NSNotFound, @"Missing PrefsWindow in %@", locale);
		NSString *windowLine = nil;
		for (NSString *line in [xib componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
			if ([line rangeOfString:@"id=\"910\" userLabel=\"PrefsWindow\""].location != NSNotFound) {
				windowLine = line;
				break;
			}
		}
		XCTAssertNotNil(windowLine);
		XCTAssertFalse([windowLine containsString:@"customClass=\"NSPanel\""],
			       @"%@ PrefsWindow must match Base NSWindow (no NSPanel)", locale);
	}
}

- (void)testPrefsControllerWiresAgentMenuAndStandardAbout {
	NSString *prefs = [self contentsOfRelativePath:@"Source/PrefsWindowController.m"];

	XCTAssertTrue([prefs containsString:@"configureAgentApplicationMenu"],
		      @"LSUIElement agents need runtime Apple-menu wiring across locales");
	XCTAssertTrue([prefs containsString:@"orderFrontStandardAboutPanel"],
		      @"About should use the standard panel so marketing/build version are correct");
	XCTAssertFalse([prefs containsString:@"[[AboutPanel alloc] init]"],
			@"Custom AboutPanel must not be the About path");
}

- (void)testPrefsTabsAndStatusItemExposeAccessibilityLabels {
	NSString *prefs = [self contentsOfRelativePath:@"Source/PrefsWindowController.m"];
	NSString *controller = [self contentsOfRelativePath:@"Source/CPController.m"];

	XCTAssertTrue([prefs containsString:@"setAccessibilityLabel:"],
		      @"Prefs tabs/toolbar need VoiceOver labels");
	XCTAssertTrue([prefs containsString:@"prefs.tab."],
		      @"Prefs panes should keep accessibility identifiers");
	XCTAssertTrue([controller containsString:@"setAccessibilityLabel:"],
		      @"Status item button needs a VoiceOver label");
	XCTAssertTrue([controller containsString:@"setAccessibilityIdentifier:"],
		      @"Status menu should expose accessibility identifiers for major items");
}

- (void)testInfoPlistHasCopyrightForStandardAbout {
	NSString *plist = [self contentsOfRelativePath:@"Info.plist"];
	XCTAssertTrue([plist containsString:@"NSHumanReadableCopyright"],
		      @"Standard About panel should have a copyright string");
}

- (void)testHelpDoesNotPresentPrinterSharingAsCurrentWithoutCaveat {
	NSString *actions = [self contentsOfRelativePath:@"Resources/ControlPlane Help/pages/actions.html"];
	NSRange heading = [actions rangeOfString:@"Toggle Printer Sharing"];
	XCTAssertTrue(heading.location != NSNotFound);
	NSString *after = [actions substringFromIndex:heading.location];
	NSRange nextH2 = [after rangeOfString:@"<h2>" options:0 range:NSMakeRange(1, after.length - 1)];
	NSString *section = nextH2.location != NSNotFound ? [after substringToIndex:nextH2.location] : after;
	BOOL marked = [section rangeOfString:@"Unsupported" options:NSCaseInsensitiveSearch].location != NSNotFound
		|| [section rangeOfString:@"retired" options:NSCaseInsensitiveSearch].location != NSNotFound
		|| [section rangeOfString:@"unavailable" options:NSCaseInsensitiveSearch].location != NSNotFound
		|| [section rangeOfString:@"helper" options:NSCaseInsensitiveSearch].location != NSNotFound;
	XCTAssertTrue(marked,
		      @"Printer Sharing Help must not be a bare current-looking stub");

	XCTAssertTrue([actions rangeOfString:@"macOS 15/16" options:NSCaseInsensitiveSearch].location != NSNotFound
			  || [actions rangeOfString:@"modern macOS" options:NSCaseInsensitiveSearch].location != NSNotFound,
		      @"Unavailable-actions section should mention modern macOS / 15/16");
}

@end
