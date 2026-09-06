//
//  ArcMigrationTests.m
//  ControlPlaneTests
//
//  Characterization checks for finishing main-app ARC and removing JSONKit (#25).
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface ArcMigrationTests : XCTestCase
@end

@implementation ArcMigrationTests

- (NSString *)srcRoot {
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
	return root;
}

- (NSString *)pbxprojContents {
	NSString *path = [[self srcRoot] stringByAppendingPathComponent:@"ControlPlane.xcodeproj/project.pbxproj"];
	NSError *error = nil;
	NSString *text = [NSString stringWithContentsOfFile:path
						   encoding:NSUTF8StringEncoding
						      error:&error];
	XCTAssertNil(error, @"Failed reading %@: %@", path, error);
	XCTAssertNotNil(text);
	return text ?: @"";
}

/// Returns the XCBuildConfiguration body for PBXNativeTarget "ControlPlane" / configName.
- (NSString *)controlPlaneTargetBuildSettingsNamed:(NSString *)configName {
	NSString *pbx = [self pbxprojContents];

	NSRegularExpression *listRe = [NSRegularExpression
		regularExpressionWithPattern:
			@"buildConfigurationList = ([A-F0-9]+) /\\* Build configuration list for PBXNativeTarget \"ControlPlane\" \\*/"
					 options:0
					   error:NULL];
	NSTextCheckingResult *listMatch =
		[listRe firstMatchInString:pbx options:0 range:NSMakeRange(0, pbx.length)];
	XCTAssertNotNil(listMatch, @"Could not find ControlPlane native target buildConfigurationList");
	NSString *listID = [pbx substringWithRange:[listMatch rangeAtIndex:1]];

	NSString *listPattern =
		[NSString stringWithFormat:@"%@ /\\* Build configuration list for PBXNativeTarget \"ControlPlane\" \\*/ = \\{([\\s\\S]*?)\\n\\t\\t\\};",
					 listID];
	NSRegularExpression *listBodyRe =
		[NSRegularExpression regularExpressionWithPattern:listPattern options:0 error:NULL];
	NSTextCheckingResult *listBodyMatch =
		[listBodyRe firstMatchInString:pbx options:0 range:NSMakeRange(0, pbx.length)];
	XCTAssertNotNil(listBodyMatch, @"Could not parse ControlPlane configuration list body");
	NSString *listBody = [pbx substringWithRange:[listBodyMatch rangeAtIndex:1]];

	NSString *configIDPattern =
		[NSString stringWithFormat:@"([A-F0-9]+) /\\* %@ \\*/",
					 [NSRegularExpression escapedPatternForString:configName]];
	NSRegularExpression *configIDRe =
		[NSRegularExpression regularExpressionWithPattern:configIDPattern options:0 error:NULL];
	NSTextCheckingResult *configIDMatch =
		[configIDRe firstMatchInString:listBody options:0 range:NSMakeRange(0, listBody.length)];
	XCTAssertNotNil(configIDMatch, @"ControlPlane list missing %@ configuration", configName);
	NSString *configID = [listBody substringWithRange:[configIDMatch rangeAtIndex:1]];

	NSString *settingsPattern =
		[NSString stringWithFormat:@"%@ /\\* %@ \\*/ = \\{[\\s\\S]*?buildSettings = \\{([\\s\\S]*?)\\n\\t\\t\\t\\};",
					 configID,
					 [NSRegularExpression escapedPatternForString:configName]];
	NSRegularExpression *settingsRe =
		[NSRegularExpression regularExpressionWithPattern:settingsPattern options:0 error:NULL];
	NSTextCheckingResult *settingsMatch =
		[settingsRe firstMatchInString:pbx options:0 range:NSMakeRange(0, pbx.length)];
	XCTAssertNotNil(settingsMatch, @"Could not parse ControlPlane %@ buildSettings", configName);
	return [pbx substringWithRange:[settingsMatch rangeAtIndex:1]];
}

- (void)assertControlPlaneTargetEnablesARCNamed:(NSString *)configName {
	NSString *settings = [self controlPlaneTargetBuildSettingsNamed:configName];
	XCTAssertTrue([settings containsString:@"CLANG_ENABLE_OBJC_ARC = YES"],
		      @"ControlPlane %@ must set CLANG_ENABLE_OBJC_ARC = YES", configName);
	XCTAssertFalse([settings containsString:@"CLANG_ENABLE_OBJC_ARC = NO"],
		       @"ControlPlane %@ must not set CLANG_ENABLE_OBJC_ARC = NO", configName);
}

- (void)testControlPlaneDebugEnablesARC {
	[self assertControlPlaneTargetEnablesARCNamed:@"Debug"];
}

- (void)testControlPlaneReleaseEnablesARC {
	[self assertControlPlaneTargetEnablesARCNamed:@"Release"];
}

- (void)testJSONKitDirectoryRemovedAndUnreferenced {
	NSString *jsonKitPath = [[self srcRoot] stringByAppendingPathComponent:@"Source/JSONKit"];
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:jsonKitPath isDirectory:&isDir];
	XCTAssertFalse(exists && isDir, @"Source/JSONKit/ must be removed");

	NSString *pbx = [self pbxprojContents];
	XCTAssertFalse([pbx rangeOfString:@"JSONKit" options:NSCaseInsensitiveSearch].location != NSNotFound,
		       @"project.pbxproj must not reference JSONKit");
}

- (void)testSourceHasNoOSAtomicUsage {
	NSString *sourceRoot = [[self srcRoot] stringByAppendingPathComponent:@"Source"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator =
		[fm enumeratorAtURL:[NSURL fileURLWithPath:sourceRoot]
	 includingPropertiesForKeys:nil
			    options:NSDirectoryEnumerationSkipsHiddenFiles
		       errorHandler:nil];

	NSRegularExpression *osAtomic =
		[NSRegularExpression regularExpressionWithPattern:@"\\bOSAtomic\\w*"
							  options:0
							    error:NULL];
	NSMutableArray<NSString *> *hits = [NSMutableArray array];
	for (NSURL *url in enumerator) {
		NSString *ext = url.pathExtension.lowercaseString;
		if (!([ext isEqualToString:@"m"] || [ext isEqualToString:@"mm"] ||
		      [ext isEqualToString:@"h"] || [ext isEqualToString:@"c"] ||
		      [ext isEqualToString:@"cpp"])) {
			continue;
		}
		NSError *error = nil;
		NSString *text = [NSString stringWithContentsOfURL:url
							  encoding:NSUTF8StringEncoding
							     error:&error];
		if (error || text == nil) {
			continue;
		}
		NSArray<NSTextCheckingResult *> *matches =
			[osAtomic matchesInString:text options:0 range:NSMakeRange(0, text.length)];
		for (NSTextCheckingResult *match in matches) {
			NSString *token = [text substringWithRange:match.range];
			// Ignore the header path itself only when paired with a real API use —
			// any OSAtomic* token (including libkern/OSAtomic.h via the basename) is banned.
			[hits addObject:[NSString stringWithFormat:@"%@: %@",
								   url.lastPathComponent, token]];
		}
		// Also catch the import path which does not match OSAtomic\w* as a whole token after /
		if ([text containsString:@"libkern/OSAtomic.h"]) {
			[hits addObject:[NSString stringWithFormat:@"%@: #import <libkern/OSAtomic.h>",
								   url.lastPathComponent]];
		}
	}

	XCTAssertEqual(hits.count, 0u, @"Source/ must not use OSAtomic* APIs: %@", hits);
}

@end
