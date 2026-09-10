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

- (void)testTestingMdDescribesAbsentBlessKeysNotTeamOURequirements {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:@"docs/TESTING.md"];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNotNil(text, @"Expected docs/TESTING.md (%@)", error);
    XCTAssertFalse([text containsString:@"Helper/XPC SMJobBless requirements use team OU"],
                   @"TESTING.md must not describe HelperSigningRequirementTests as SMJobBless team-OU checks (#215)");
    XCTAssertTrue([text containsString:@"omit leftover SMAuthorizedClients"],
                  @"TESTING.md must say HelperSigningRequirementTests asserts leftover bless keys are absent");
    XCTAssertTrue([text containsString:@"CPHelperClientGateTests"],
                  @"TESTING.md must point the listener gate at CPHelperClientGateTests");
}

@end
