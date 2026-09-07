//
//  RemoteDesktopRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "RemoteDesktopEvidenceSource.h"

@interface RemoteDesktopRuleMatchTests : XCTestCase
@end

@implementation RemoteDesktopRuleMatchTests

- (void)testConnectedMatchesYesRule {
    RemoteDesktopEvidenceSource *source = [[RemoteDesktopEvidenceSource alloc] initForMatchingTests];
    [source setUserConnectedForTesting:YES];
    NSDictionary *rule = @{ @"parameter": @"Yes" };
    XCTAssertTrue([source doesRuleMatch:rule]);
    XCTAssertTrue(source.receivedRemoteDesktopNotify);
}

- (void)testConnectedMissesNoRule {
    RemoteDesktopEvidenceSource *source = [[RemoteDesktopEvidenceSource alloc] initForMatchingTests];
    [source setUserConnectedForTesting:YES];
    NSDictionary *rule = @{ @"parameter": @"No" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

- (void)testDisconnectedMatchesNoRule {
    RemoteDesktopEvidenceSource *source = [[RemoteDesktopEvidenceSource alloc] initForMatchingTests];
    [source setUserConnectedForTesting:NO];
    NSDictionary *rule = @{ @"parameter": @"No" };
    XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testDisconnectedMissesYesRule {
    RemoteDesktopEvidenceSource *source = [[RemoteDesktopEvidenceSource alloc] initForMatchingTests];
    [source setUserConnectedForTesting:NO];
    NSDictionary *rule = @{ @"parameter": @"Yes" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

- (void)testViewerNamesUserInfoSetsConnectedWithoutDistributedCenter {
    RemoteDesktopEvidenceSource *source = [[RemoteDesktopEvidenceSource alloc] initForMatchingTests];
    [source applyViewerNamesNotificationUserInfoForTesting:@{ @"ViewerNames": @[ @"alice" ] }];
    XCTAssertTrue(source.userConnected);
    XCTAssertTrue(source.receivedRemoteDesktopNotify);
    XCTAssertTrue([source doesRuleMatch:@{ @"parameter": @"Yes" }]);
}

- (void)testEmptyViewerNamesSetsDisconnected {
    RemoteDesktopEvidenceSource *source = [[RemoteDesktopEvidenceSource alloc] initForMatchingTests];
    [source setUserConnectedForTesting:YES];
    [source applyViewerNamesNotificationUserInfoForTesting:@{ @"ViewerNames": @[] }];
    XCTAssertFalse(source.userConnected);
    XCTAssertTrue([source doesRuleMatch:@{ @"parameter": @"No" }]);
}

@end
