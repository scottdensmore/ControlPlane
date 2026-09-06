//
//  CPMenuBarImageTests.m
//  ControlPlaneTests
//
//  Characterizes menu-bar template prep (#89) and Asset Catalog wiring (#32).
//

#import <XCTest/XCTest.h>
#import "CPMenuBarImage.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPMenuBarImageTests : XCTestCase
@end

@implementation CPMenuBarImageTests

- (NSString *)srcRoot {
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
	return root;
}

- (NSImage *)sampleImage {
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
	[image lockFocus];
	[[NSColor blackColor] set];
	NSRectFill(NSMakeRect(0, 0, 64, 64));
	[image unlockFocus];
	[image setTemplate:NO];
	return image;
}

- (void)testConfigureAsMenuBarTemplateCopiesAndSetsSizeAndTemplateFlag {
	NSImage *image = [self sampleImage];
	XCTAssertFalse(image.isTemplate);

	NSImage *configured = [CPMenuBarImage configureAsMenuBarTemplate:image
								 size:NSMakeSize(18, 18)];
	XCTAssertNotEqual(configured, image,
			  @"Must copy so shared catalog/bundle images stay non-template for About");
	XCTAssertTrue(NSEqualSizes(configured.size, NSMakeSize(18, 18)));
	XCTAssertTrue(configured.isTemplate,
		      @"Status-item images must be templates for Liquid Glass contrast");
	XCTAssertFalse(image.isTemplate,
		       @"Original image must remain untouched");
}

- (void)testConfigureAsMenuBarTemplateReturnsNilForNilImage {
	XCTAssertNil([CPMenuBarImage configureAsMenuBarTemplate:nil size:NSMakeSize(18, 18)]);
}

- (void)testMenuBarImageNamedReturnsNilForEmptyName {
	XCTAssertNil([CPMenuBarImage menuBarImageNamed:@"" size:NSMakeSize(18, 18)]);
	XCTAssertNil([CPMenuBarImage menuBarImageNamed:nil size:NSMakeSize(18, 18)]);
}

- (void)testAssetCatalogMarksMenuBarIconsAsTemplate {
	NSString *root = [self srcRoot];
	NSArray<NSString *> *names = @[ @"cp-icon", @"cp-icon-active", @"cp-icon-inactive" ];
	for (NSString *name in names) {
		NSString *path =
		    [root stringByAppendingPathComponent:
			     [NSString stringWithFormat:
				      @"Resources/Images.xcassets/%@.imageset/Contents.json", name]];
		NSError *error = nil;
		NSString *json = [NSString stringWithContentsOfFile:path
							   encoding:NSUTF8StringEncoding
							      error:&error];
		XCTAssertNil(error, @"Missing imageset Contents.json for %@", name);
		XCTAssertTrue([json containsString:@"\"template-rendering-intent\" : \"template\""],
			      @"%@ must declare template rendering for light/dark menu bars", name);
	}
}

- (void)testAssetCatalogProvidesColoredBrandAndAppIcon {
	NSString *root = [self srcRoot];
	NSString *brand =
	    [root stringByAppendingPathComponent:
		     @"Resources/Images.xcassets/ControlPlane.imageset/Contents.json"];
	NSString *appIcon =
	    [root stringByAppendingPathComponent:
		     @"Resources/Images.xcassets/AppIcon.appiconset/Contents.json"];
	NSError *error = nil;
	NSString *brandJSON = [NSString stringWithContentsOfFile:brand
							encoding:NSUTF8StringEncoding
							   error:&error];
	XCTAssertNil(error);
	XCTAssertTrue([brandJSON containsString:@"\"template-rendering-intent\" : \"original\""],
		      @"About/brand image must stay original (non-template)");

	NSString *appJSON = [NSString stringWithContentsOfFile:appIcon
						      encoding:NSUTF8StringEncoding
							 error:&error];
	XCTAssertNil(error);
	XCTAssertTrue([appJSON containsString:@"icon_512x512"],
		      @"AppIcon.appiconset should include macOS icon slots");
}

- (void)testLegacyAppIcnsKeptForBundleIconFile {
	NSString *root = [self srcRoot];
	NSString *icns =
	    [root stringByAppendingPathComponent:@"Resources/controlplane.icns"];
	NSString *info =
	    [root stringByAppendingPathComponent:@"Info.plist"];
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:icns],
		      @"Keep controlplane.icns for CFBundleIconFile legacy");
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:info];
	XCTAssertEqualObjects(plist[@"CFBundleIconFile"], @"controlplane.icns");
}

- (void)testStatusItemUsesButtonImageAPINotDeprecatedSetter {
	NSString *root = [self srcRoot];
	NSString *path = [root stringByAppendingPathComponent:@"Source/CPController.m"];
	NSError *error = nil;
	NSString *source = [NSString stringWithContentsOfFile:path
						    encoding:NSUTF8StringEncoding
						       error:&error];
	XCTAssertNil(error);
	XCTAssertTrue([source containsString:@"sbItem.button.image"],
		      @"Status item must use button.image API");
	XCTAssertTrue([source containsString:@"sbItem.button.title"] ||
			  [source containsString:@"sbItem.button.attributedTitle"],
		      @"Status item title must use button API");
	XCTAssertFalse([source containsString:@"[sbItem setImage:"],
		       @"Avoid deprecated NSStatusItem setImage:");
	XCTAssertFalse([source containsString:@"[sbItem setTitle:"],
		       @"Avoid deprecated NSStatusItem setTitle:");
	XCTAssertTrue([source containsString:@"menuBarImageNamed:"],
		      @"prepareImageForMenubar should load via CPMenuBarImage catalog helper");
}

- (void)testPrefsAndAboutActivateBeforeShowingWindows {
	// Source characterization: LSUIElement agents must activate before windows
	// become usable on Tahoe. Prefer this over flaky status-item UI tests.
	NSString *root = [self srcRoot];

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
