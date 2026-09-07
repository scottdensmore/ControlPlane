//
//  OrphanHygieneTests.m
//  ControlPlaneTests
//
//  #133: Characterize orphan / archive status for IPEvidenceSource,
//  FirewallRuleAction, and VPNAction so agents do not re-enable gated paths.
//

#import <XCTest/XCTest.h>
#import "FirewallRuleAction.h"
#import "VPNAction.h"
#import "IPAddrEvidenceSource.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface OrphanHygieneTests : XCTestCase
@end

@implementation OrphanHygieneTests

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

- (BOOL)fileExistsAtRelativePath:(NSString *)relativePath {
    NSString *path = [self.srcRoot stringByAppendingPathComponent:relativePath];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

#pragma mark - IPEvidenceSource deleted (superseded by IPAddrEvidenceSource)

- (void)testLegacyIPEvidenceSourceSourcesAreGone {
    XCTAssertFalse([self fileExistsAtRelativePath:@"Source/IPEvidenceSource.h"],
                   @"IPEvidenceSource.h must be removed (#133)");
    XCTAssertFalse([self fileExistsAtRelativePath:@"Source/IPEvidenceSource.m"],
                   @"IPEvidenceSource.m must be removed (#133)");
}

- (void)testProjectDoesNotReferenceIPEvidenceSource {
    NSString *pbx = [self contentsOfRelativePath:@"ControlPlane.xcodeproj/project.pbxproj"];
    XCTAssertFalse([pbx containsString:@"IPEvidenceSource"],
                   @"project.pbxproj must not reference deleted IPEvidenceSource (#133)");
}

- (void)testEvidenceRegistryUsesIPAddrNotLegacyIPEvidence {
    NSString *source = [self contentsOfRelativePath:@"Source/EvidenceSource.m"];
    XCTAssertTrue([source containsString:@"IPAddrEvidenceSource"],
                  @"EvidenceSourceSetController must register IPAddrEvidenceSource");
    XCTAssertFalse([source containsString:@"IPEvidenceSource"],
                   @"EvidenceSourceSetController must not reference IPEvidenceSource (#133)");
    XCTAssertEqualObjects(NSStringFromClass([IPAddrEvidenceSource class]), @"IPAddrEvidenceSource");
}

#pragma mark - FirewallRule / VPN archived gated stubs (tests-only)

- (void)testFirewallRuleAndVPNRemainGated {
    XCTAssertFalse([FirewallRuleAction isActionApplicableToSystem],
                   @"FirewallRuleAction must stay gated (#33/#133)");
    XCTAssertFalse([VPNAction isActionApplicableToSystem],
                   @"VPNAction must stay gated (#33/#133)");
}

- (void)testShippingActionRegistryOmitsFirewallRuleAndVPN {
    NSString *actionM = [self contentsOfRelativePath:@"Source/Action.m"];

    NSRegularExpression *liveVPN =
        [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\[VPNAction class\\]"
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:NULL];
    NSRegularExpression *liveFW =
        [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\[FirewallRuleAction class\\]"
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:NULL];
    XCTAssertEqual([liveVPN numberOfMatchesInString:actionM options:0 range:NSMakeRange(0, actionM.length)], 0u,
                   @"VPNAction must not be an active registry entry (#133)");
    XCTAssertEqual([liveFW numberOfMatchesInString:actionM options:0 range:NSMakeRange(0, actionM.length)], 0u,
                   @"FirewallRuleAction must not be an active registry entry (#133)");

    XCTAssertTrue([actionM containsString:@"//[VPNAction class]"],
                  @"Action.m should keep a commented VPN archive marker (#133)");
    XCTAssertTrue([actionM containsString:@"//[FirewallRuleAction class]"],
                  @"Action.m should keep a commented FirewallRule archive marker (#133)");

    NSRegularExpression *liveImportFW =
        [NSRegularExpression regularExpressionWithPattern:@"^\\s*#import \"FirewallRuleAction\\.h\""
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:NULL];
    NSRegularExpression *liveImportVPN =
        [NSRegularExpression regularExpressionWithPattern:@"^\\s*#import \"VPNAction\\.h\""
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:NULL];
    XCTAssertEqual([liveImportFW numberOfMatchesInString:actionM options:0 range:NSMakeRange(0, actionM.length)], 0u,
                   @"App Action.m must not import archived FirewallRuleAction (#133)");
    XCTAssertEqual([liveImportVPN numberOfMatchesInString:actionM options:0 range:NSMakeRange(0, actionM.length)], 0u,
                   @"App Action.m must not import archived VPNAction (#133)");
}

- (void)testFirewallRuleAndVPNAreTestsOnlyInProject {
    NSString *pbx = [self contentsOfRelativePath:@"ControlPlane.xcodeproj/project.pbxproj"];

    // Tests target keeps both for ApplicabilityCharacterizationTests.
    XCTAssertTrue([pbx containsString:@"A51FWRU01B51WIRE00000033 /* FirewallRuleAction.m in Sources */"],
                  @"FirewallRuleAction.m must remain in ControlPlaneTests (#133)");
    XCTAssertTrue([pbx containsString:@"A51VPNA01B51WIRE00000033 /* VPNAction.m in Sources */"],
                  @"VPNAction.m must remain in ControlPlaneTests (#133)");

    // App target must not compile either (8DCB4358 was the historical app PBXBuildFile id).
    XCTAssertFalse([pbx containsString:@"8DCB43580C4DBABD00E71D28"],
                   @"FirewallRuleAction must not be in the ControlPlane app Sources phase (#133)");

    // VPN never had an app PBXBuildFile id in this tree; ensure no second VPN Sources entry
    // beyond the tests one by counting "VPNAction.m in Sources" occurrences.
    NSUInteger vpnSources = 0;
    NSString *needle = @"VPNAction.m in Sources";
    NSRange search = NSMakeRange(0, pbx.length);
    while (search.location < pbx.length) {
        NSRange found = [pbx rangeOfString:needle options:0 range:search];
        if (found.location == NSNotFound) {
            break;
        }
        vpnSources++;
        search.location = NSMaxRange(found);
        search.length = pbx.length - search.location;
    }
    // One PBXBuildFile definition + one Sources-phase reference = 2.
    XCTAssertEqual(vpnSources, 2u,
                   @"VPNAction.m should appear only as the ControlPlaneTests Sources membership (#133)");

    NSUInteger fwSources = 0;
    needle = @"FirewallRuleAction.m in Sources";
    search = NSMakeRange(0, pbx.length);
    while (search.location < pbx.length) {
        NSRange found = [pbx rangeOfString:needle options:0 range:search];
        if (found.location == NSNotFound) {
            break;
        }
        fwSources++;
        search.location = NSMaxRange(found);
        search.length = pbx.length - search.location;
    }
    XCTAssertEqual(fwSources, 2u,
                   @"FirewallRuleAction.m should appear only as the ControlPlaneTests Sources membership (#133)");
}

- (void)testArchiveHeadersDocumentGatedOrphanStatus {
    NSString *fw = [self contentsOfRelativePath:@"Source/FirewallRuleAction.h"];
    NSString *vpn = [self contentsOfRelativePath:@"Source/VPNAction.h"];
    for (NSString *header in @[ fw, vpn ]) {
        XCTAssertTrue([header rangeOfString:@"ARCHIVE" options:NSCaseInsensitiveSearch].location != NSNotFound,
                      @"Archived action headers must say ARCHIVE (#133)");
        XCTAssertTrue([header containsString:@"isActionApplicableToSystem"],
                      @"Archived action headers must mention gating (#133)");
        XCTAssertTrue([header rangeOfString:@"Do not re-enable" options:NSCaseInsensitiveSearch].location != NSNotFound,
                      @"Archived action headers must warn against re-enable (#133)");
    }
}

@end
