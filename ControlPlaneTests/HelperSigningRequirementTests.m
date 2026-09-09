//
//  HelperSigningRequirementTests.m
//  ControlPlaneTests
//
//  Source-level checks that leftover SMJobBless plist keys are absent (#185).
//  Does not attempt to bless or codesign. The listener allowlist is CPHelperClientGate.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface HelperSigningRequirementTests : XCTestCase
@end

@implementation HelperSigningRequirementTests

- (NSDictionary *)plistAtRelativePath:(NSString *)relativePath {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:relativePath];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    XCTAssertNotNil(plist, @"Expected plist at %@", path);
    return plist;
}

- (void)testHelperInfoPlistOmitsSMAuthorizedClients {
    NSDictionary *plist = [self plistAtRelativePath:@"CPHelperTool/HelperTool-Info.plist"];
    XCTAssertNil(plist[@"SMAuthorizedClients"],
                 @"SMAuthorizedClients is leftover SMJobBless; the client gate is CPHelperClientGate");
}

- (void)testXPCInfoPlistOmitsSMPrivilegedExecutables {
    NSDictionary *plist = [self plistAtRelativePath:@"CPXPCService/Info.plist"];
    XCTAssertNil(plist[@"SMPrivilegedExecutables"],
                 @"SMPrivilegedExecutables is leftover SMJobBless; the client gate is CPHelperClientGate");
}

@end
