//
//  PowerRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "PowerEvidenceSource.h"

@interface PowerRuleMatchTests : XCTestCase
@end

@implementation PowerRuleMatchTests

- (void)testBatteryStatusMatches {
    PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
    [source setPowerStatusForTesting:@"Battery"];
    NSDictionary *rule = @{ @"parameter": @"Battery" };
    XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testACStatusMissesBatteryRule {
    PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
    [source setPowerStatusForTesting:@"A/C"];
    NSDictionary *rule = @{ @"parameter": @"Battery" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

@end
