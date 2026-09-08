//
//  CPHelperClientGateTests.m
//  ControlPlaneTests
//
//  Client code-signing gate for the privileged helper (#166).
//  Injects identifier, team ID, and signed-or-not. Does not bless a helper.
//

#import <XCTest/XCTest.h>
#import "CPHelperClientGate.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPHelperClientGateTests : XCTestCase
@end

@implementation CPHelperClientGateTests

- (void)testAcceptsSignedExpectedCPXPCServiceClient
{
    XCTAssertTrue([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedClientIdentifier
                                                         teamIdentifier:kCPHelperAuthorizedClientTeamIdentifier
                                                               isSigned:YES]);
}

- (void)testAcceptsSignedControlPlaneAppClient
{
    // Privileged commands are sent by the app over the helper endpoint after
    // connectWithEndpointReply:. That hop hits the same listener (#166 review).
    XCTAssertTrue([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedAppIdentifier
                                                         teamIdentifier:kCPHelperAuthorizedClientTeamIdentifier
                                                               isSigned:YES],
                  @"ControlPlane app must be accepted on the helper endpoint hop");
}

- (void)testRejectsWrongIdentifier
{
    XCTAssertFalse([CPHelperClientGate shouldAcceptClientWithIdentifier:@"com.example.Stranger"
                                                           teamIdentifier:kCPHelperAuthorizedClientTeamIdentifier
                                                                 isSigned:YES],
                   @"Wrong code-signing identifier must be rejected");
}

- (void)testRejectsMissingTeam
{
    XCTAssertFalse([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedClientIdentifier
                                                           teamIdentifier:nil
                                                                 isSigned:YES],
                   @"Missing team ID must be rejected");
    XCTAssertFalse([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedClientIdentifier
                                                           teamIdentifier:@""
                                                                 isSigned:YES],
                   @"Empty team ID must be rejected");
}

- (void)testRejectsWrongTeam
{
    XCTAssertFalse([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedClientIdentifier
                                                           teamIdentifier:@"AAAAAAAAAA"
                                                                 isSigned:YES],
                   @"Wrong team ID must be rejected");
}

- (void)testRejectsUnsignedClientEvenWhenIdentifierAndTeamMatch
{
    XCTAssertFalse([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedClientIdentifier
                                                           teamIdentifier:kCPHelperAuthorizedClientTeamIdentifier
                                                                 isSigned:NO],
                   @"Unsigned XPC service must be rejected");
    XCTAssertFalse([CPHelperClientGate shouldAcceptClientWithIdentifier:kCPHelperAuthorizedAppIdentifier
                                                           teamIdentifier:kCPHelperAuthorizedClientTeamIdentifier
                                                                 isSigned:NO],
                   @"Unsigned app must be rejected");
}

- (NSDictionary *)plistAtRelativePath:(NSString *)relativePath
{
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:relativePath];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    XCTAssertNotNil(plist, @"Expected plist at %@", path);
    return plist;
}

- (void)testAuthorizedClientConstantsMatchSMAuthorizedClients
{
    XCTAssertEqualObjects(kCPHelperAuthorizedClientIdentifier, @"com.scottdensmore.CPXPCService");
    XCTAssertEqualObjects(kCPHelperAuthorizedAppIdentifier, @"com.scottdensmore.ControlPlane");
    XCTAssertEqualObjects(kCPHelperAuthorizedClientTeamIdentifier, @"27ZDER873F");

    NSDictionary *appPlist = [self plistAtRelativePath:@"Info.plist"];
    NSArray *urlTypes = appPlist[@"CFBundleURLTypes"];
    XCTAssertTrue([urlTypes isKindOfClass:[NSArray class]]);
    NSString *urlName = [urlTypes.firstObject objectForKey:@"CFBundleURLName"];
    XCTAssertEqualObjects(kCPHelperAuthorizedAppIdentifier, urlName,
                          @"App allowlist identifier must match Info.plist CFBundleURLName");

    NSDictionary *helperPlist = [self plistAtRelativePath:@"CPHelperTool/HelperTool-Info.plist"];
    NSArray *clients = helperPlist[@"SMAuthorizedClients"];
    XCTAssertTrue([clients isKindOfClass:[NSArray class]]);
    XCTAssertEqual(clients.count, 1u);
    NSString *blessRequirement = clients.firstObject;
    XCTAssertEqualObjects(blessRequirement,
                          [CPHelperClientGate smAuthorizedClientsRequirementForIdentifier:kCPHelperAuthorizedClientIdentifier],
                          @"Bless SMAuthorizedClients must stay the XPC-service requirement");
    XCTAssertFalse([blessRequirement containsString:kCPHelperAuthorizedAppIdentifier],
                   @"Do not change SMAuthorizedClients; app identifier is runtime-only");
}

- (void)testListenerRequirementMatchesSMAuthorizedClientsClauses
{
    NSString *listenerRequirement = [CPHelperClientGate listenerCodeSigningRequirement];
    NSString *blessRequirement = [CPHelperClientGate smAuthorizedClientsRequirementForIdentifier:kCPHelperAuthorizedClientIdentifier];

    XCTAssertTrue([CPHelperClientGate isValidCodeSigningRequirement:listenerRequirement],
                  @"Listener requirement must be a valid Security requirement string");
    XCTAssertTrue([CPHelperClientGate isValidCodeSigningRequirement:blessRequirement]);

    XCTAssertTrue([listenerRequirement containsString:@"identifier \"com.scottdensmore.CPXPCService\""]);
    XCTAssertTrue([listenerRequirement containsString:@"identifier \"com.scottdensmore.ControlPlane\""]);
    XCTAssertTrue([listenerRequirement containsString:@"anchor apple generic"]);
    XCTAssertTrue([listenerRequirement containsString:@"certificate leaf[subject.OU] = \"27ZDER873F\""]);
    XCTAssertTrue([listenerRequirement containsString:@"1.2.840.113635.100.6.2.1"]);
    XCTAssertTrue([listenerRequirement containsString:@"1.2.840.113635.100.6.2.6"]);

    // Same tail as the bless string, so the clauses cannot drift apart.
    NSString *tail = [blessRequirement substringFromIndex:[blessRequirement rangeOfString:@"anchor apple generic"].location];
    XCTAssertTrue([listenerRequirement hasSuffix:tail]);
}

- (NSString *)helperToolImplementation
{
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:@"CPHelperTool/CPHelperTool.m"];
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNotNil(source, @"Failed reading %@: %@", path, error);
    return source;
}

- (NSString *)clientGateSource
{
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:@"CPHelperTool/CPHelperClientGate.m"];
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNotNil(source, @"Failed reading %@: %@", path, error);
    return source;
}

- (void)testListenerAppliesSMAuthorizedClientsRequirementBeforeResume
{
    // Mismatched peers must be rejected by the listener requirement (macOS 13+),
    // not by PID guest lookup alone.
    NSString *tool = [self helperToolImplementation];
    NSString *gate = [self clientGateSource];

    NSRange requirement = [tool rangeOfString:@"setConnectionCodeSigningRequirement:"];
    NSRange resume = [tool rangeOfString:@"[self.listener resume]"];
    XCTAssertNotEqual(requirement.location, NSNotFound,
                      @"listener must apply setConnectionCodeSigningRequirement: (#166 review)");
    XCTAssertNotEqual(resume.location, NSNotFound);
    XCTAssertLessThan(requirement.location, resume.location,
                      @"requirement must be set before the listener resumes");

    XCTAssertFalse([gate containsString:@"kSecGuestAttributePid"],
                   @"live accept must not use PID guest lookup alone");
    XCTAssertFalse([tool containsString:@"kSecGuestAttributePid"],
                   @"helper listener must not accept on PID guest lookup alone");
}

@end
