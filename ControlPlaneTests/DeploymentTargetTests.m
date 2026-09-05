//
//  DeploymentTargetTests.m
//  ControlPlaneTests
//
//  Ensures the macOS-15 product line declares MACOSX_DEPLOYMENT_TARGET 15.0 (#40).
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface DeploymentTargetTests : XCTestCase
@end

@implementation DeploymentTargetTests

- (NSString *)srcRoot {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    return root;
}

- (NSString *)contentsOfRelativePath:(NSString *)relativePath {
    NSString *path = [self.srcRoot stringByAppendingPathComponent:relativePath];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    XCTAssertNil(error, @"Failed reading %@: %@", path, error);
    XCTAssertNotNil(text);
    return text ?: @"";
}

- (void)assertNoStaleDeploymentTargetInFile:(NSString *)relativePath {
    NSString *text = [self contentsOfRelativePath:relativePath];
    XCTAssertFalse([text containsString:@"MACOSX_DEPLOYMENT_TARGET = 14.5"],
                   @"%@ still sets MACOSX_DEPLOYMENT_TARGET to 14.5", relativePath);
    XCTAssertFalse([text containsString:@"MACOSX_DEPLOYMENT_TARGET'] = '14.5'"],
                   @"%@ still sets MACOSX_DEPLOYMENT_TARGET to 14.5", relativePath);
    // xcodeprojgen / new_target platform version literal
    NSRegularExpression *legacyPlatform =
        [NSRegularExpression regularExpressionWithPattern:@":osx,\\s*'14\\.5'"
                                                  options:0
                                                    error:NULL];
    NSUInteger legacyHits =
        [legacyPlatform numberOfMatchesInString:text options:0 range:NSMakeRange(0, text.length)];
    XCTAssertEqual(legacyHits, 0u, @"%@ still uses :osx, '14.5' for test targets", relativePath);
}

- (void)testMainProjectDeclaresFifteen {
    NSString *pbx = [self contentsOfRelativePath:@"ControlPlane.xcodeproj/project.pbxproj"];
    XCTAssertTrue([pbx containsString:@"MACOSX_DEPLOYMENT_TARGET = 15.0"],
                  @"ControlPlane.xcodeproj must set MACOSX_DEPLOYMENT_TARGET = 15.0");
    [self assertNoStaleDeploymentTargetInFile:@"ControlPlane.xcodeproj/project.pbxproj"];
}

- (void)testAddTestTargetsScriptDeclaresFifteen {
    NSString *script = [self contentsOfRelativePath:@"scripts/add-test-targets.rb"];
    XCTAssertTrue([script containsString:@"MACOSX_DEPLOYMENT_TARGET'] = '15.0'"] ||
                  [script containsString:@":osx, '15.0'"],
                  @"scripts/add-test-targets.rb must use 15.0");
    [self assertNoStaleDeploymentTargetInFile:@"scripts/add-test-targets.rb"];
}

- (void)testInfoPlistUsesDeploymentTargetVariable {
    NSString *plist = [self contentsOfRelativePath:@"Info.plist"];
    XCTAssertTrue([plist containsString:@"LSMinimumSystemVersion"],
                  @"Info.plist must declare LSMinimumSystemVersion");
    XCTAssertTrue([plist containsString:@"${MACOSX_DEPLOYMENT_TARGET}"],
                  @"LSMinimumSystemVersion must use ${MACOSX_DEPLOYMENT_TARGET}");
    XCTAssertFalse([plist containsString:@"<string>14.5</string>"],
                   @"Info.plist must not hardcode 14.5");
}

@end
