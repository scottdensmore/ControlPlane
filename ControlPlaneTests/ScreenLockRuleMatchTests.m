//
//  ScreenLockRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "ScreenLockEvidenceSource.h"

@interface ScreenLockRuleMatchTests : XCTestCase
@end

@implementation ScreenLockRuleMatchTests

- (void)testLockedMatchesLockRule {
    ScreenLockEvidenceSource *source = [[ScreenLockEvidenceSource alloc] initForMatchingTests];
    [source setScreenLockedForTesting:YES];
    NSDictionary *rule = @{ @"parameter": @"lock" };
    XCTAssertTrue([source doesRuleMatch:rule]);
    XCTAssertTrue(source.receivedLockStateNotify);
}

- (void)testLockedMissesUnlockRule {
    ScreenLockEvidenceSource *source = [[ScreenLockEvidenceSource alloc] initForMatchingTests];
    [source setScreenLockedForTesting:YES];
    NSDictionary *rule = @{ @"parameter": @"unlock" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

- (void)testUnlockedMatchesUnlockRule {
    ScreenLockEvidenceSource *source = [[ScreenLockEvidenceSource alloc] initForMatchingTests];
    [source setScreenLockedForTesting:NO];
    NSDictionary *rule = @{ @"parameter": @"unlock" };
    XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testUnlockedMissesLockRule {
    ScreenLockEvidenceSource *source = [[ScreenLockEvidenceSource alloc] initForMatchingTests];
    [source setScreenLockedForTesting:NO];
    NSDictionary *rule = @{ @"parameter": @"lock" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

- (void)testScreenDidLockUpdatesWithoutDistributedCenter {
    ScreenLockEvidenceSource *source = [[ScreenLockEvidenceSource alloc] initForMatchingTests];
    [source setScreenLockedForTesting:NO];
    [source screenDidLock:nil];
    XCTAssertTrue(source.screenIsLocked);
    XCTAssertTrue(source.receivedLockStateNotify);
    XCTAssertTrue([source doesRuleMatch:@{ @"parameter": @"lock" }]);
}

- (void)testScreenDidUnlockUpdatesWithoutDistributedCenter {
    ScreenLockEvidenceSource *source = [[ScreenLockEvidenceSource alloc] initForMatchingTests];
    [source setScreenLockedForTesting:YES];
    [source screenDidUnlock:nil];
    XCTAssertFalse(source.screenIsLocked);
    XCTAssertTrue([source doesRuleMatch:@{ @"parameter": @"unlock" }]);
}

@end
