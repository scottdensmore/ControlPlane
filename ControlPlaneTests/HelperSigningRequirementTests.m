//
//  HelperSigningRequirementTests.m
//  ControlPlaneTests
//
//  Source-level checks for SMJobBless designated requirements (#28).
//  Does not attempt to bless or codesign.
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

- (void)assertTeamRequirement:(NSString *)requirement expectedIdentifier:(NSString *)identifier {
    XCTAssertNotNil(requirement);
    NSString *needle = [NSString stringWithFormat:@"identifier \"%@\"", identifier];
    XCTAssertTrue([requirement containsString:needle],
                  @"Requirement should pin identifier %@", identifier);
    XCTAssertTrue([requirement containsString:@"subject.OU"],
                  @"Requirement should reference certificate leaf subject.OU");
    XCTAssertTrue([requirement containsString:@"27ZDER873F"],
                  @"Requirement should use team OU 27ZDER873F");
    XCTAssertFalse([requirement containsString:@"Scott Densmore"],
                   @"Requirement must not pin a personal certificate CN");
    XCTAssertTrue([requirement containsString:@"1.2.840.113635.100.6.2.1"],
                  @"Requirement should allow Apple Development intermediate");
    XCTAssertTrue([requirement containsString:@"1.2.840.113635.100.6.2.6"],
                  @"Requirement should allow Developer ID intermediate");
}

- (void)testHelperAuthorizedClientsUseTeamRequirement {
    NSDictionary *plist = [self plistAtRelativePath:@"CPHelperTool/HelperTool-Info.plist"];
    NSArray *clients = plist[@"SMAuthorizedClients"];
    XCTAssertTrue([clients isKindOfClass:[NSArray class]]);
    XCTAssertEqual(clients.count, 1u);
    [self assertTeamRequirement:clients.firstObject
            expectedIdentifier:@"com.scottdensmore.CPXPCService"];
}

- (void)testXPCPrivilegedExecutableUsesTeamRequirement {
    NSDictionary *plist = [self plistAtRelativePath:@"CPXPCService/Info.plist"];
    NSDictionary *executables = plist[@"SMPrivilegedExecutables"];
    XCTAssertTrue([executables isKindOfClass:[NSDictionary class]]);
    NSString *requirement = executables[@"com.scottdensmore.CPHelperTool"];
    [self assertTeamRequirement:requirement
            expectedIdentifier:@"com.scottdensmore.CPHelperTool"];
}

@end
