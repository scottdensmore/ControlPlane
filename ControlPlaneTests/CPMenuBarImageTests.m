//
//  CPMenuBarImageTests.m
//  ControlPlaneTests
//
//  Characterizes menu-bar template image prep for Tahoe Liquid Glass (#89).
//

#import <XCTest/XCTest.h>
#import "CPMenuBarImage.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPMenuBarImageTests : XCTestCase
@end

@implementation CPMenuBarImageTests

- (NSImage *)sampleImage {
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
	[image lockFocus];
	[[NSColor blackColor] set];
	NSRectFill(NSMakeRect(0, 0, 64, 64));
	[image unlockFocus];
	[image setTemplate:NO];
	return image;
}

- (void)testConfigureAsMenuBarTemplateSetsSizeAndTemplateFlag {
	NSImage *image = [self sampleImage];
	XCTAssertFalse(image.isTemplate);

	NSImage *configured = [CPMenuBarImage configureAsMenuBarTemplate:image
								 size:NSMakeSize(18, 18)];
	XCTAssertEqual(configured, image);
	XCTAssertTrue(NSEqualSizes(configured.size, NSMakeSize(18, 18)));
	XCTAssertTrue(configured.isTemplate,
		      @"Status-item images must be templates for Liquid Glass contrast");
}

- (void)testConfigureAsMenuBarTemplateReturnsNilForNilImage {
	XCTAssertNil([CPMenuBarImage configureAsMenuBarTemplate:nil size:NSMakeSize(18, 18)]);
}

- (void)testPrefsAndAboutActivateBeforeShowingWindows {
	// Source characterization: LSUIElement agents must activate before windows
	// become usable on Tahoe. Prefer this over flaky status-item UI tests.
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");

	NSString *prefsPath = [root stringByAppendingPathComponent:@"Source/PrefsWindowController.m"];
	NSString *controllerPath = [root stringByAppendingPathComponent:@"Source/CPController.m"];

	NSError *error = nil;
	NSString *prefsSource = [NSString stringWithContentsOfFile:prefsPath
							  encoding:NSUTF8StringEncoding
							     error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(prefsSource);

	NSString *controllerSource = [NSString stringWithContentsOfFile:controllerPath
							       encoding:NSUTF8StringEncoding
								  error:&error];
	XCTAssertNil(error);
	XCTAssertNotNil(controllerSource);

	XCTAssertTrue([prefsSource containsString:@"activateIgnoringOtherApps:YES"],
		      @"PrefsWindowController must activate before Preferences/About");
	XCTAssertTrue([prefsSource rangeOfString:@"runPreferences:"].location != NSNotFound);
	XCTAssertTrue([prefsSource rangeOfString:@"runAbout:"].location != NSNotFound);

	// Match the implementation body only (skip the ';' prototype declaration).
	NSRegularExpression *re =
	    [NSRegularExpression regularExpressionWithPattern:
		 @"- \\(BOOL\\)applicationShouldHandleReopen:[^;{]+\\{([^}]*)\\}"
						  options:0
						    error:&error];
	XCTAssertNil(error);
	NSTextCheckingResult *match =
	    [re firstMatchInString:controllerSource
			   options:0
			     range:NSMakeRange(0, controllerSource.length)];
	XCTAssertNotNil(match, @"Expected applicationShouldHandleReopen implementation");
	NSString *body = [controllerSource substringWithRange:[match rangeAtIndex:1]];
	XCTAssertTrue([body containsString:@"activateIgnoringOtherApps:YES"],
		      @"applicationShouldHandleReopen must activate before showing prefs");
}

@end
