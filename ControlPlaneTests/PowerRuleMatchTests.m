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

- (void)testBatteryLevelBelowMatches {
    PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
    [source setBatteryPercentForTesting:15 lowPowerMode:NO];
    NSDictionary *below = @{ @"type": @"BatteryLevel", @"parameter": @"below:20" };
    NSDictionary *above = @{ @"type": @"BatteryLevel", @"parameter": @"above:80" };
    XCTAssertTrue([source doesRuleMatch:below]);
    XCTAssertFalse([source doesRuleMatch:above]);
}

- (void)testBatteryLevelAboveMatches {
    PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
    [source setBatteryPercentForTesting:90 lowPowerMode:NO];
    NSDictionary *above = @{ @"type": @"BatteryLevel", @"parameter": @"above:80" };
    NSDictionary *below = @{ @"type": @"BatteryLevel", @"parameter": @"below:20" };
    XCTAssertTrue([source doesRuleMatch:above]);
    XCTAssertFalse([source doesRuleMatch:below]);
}

- (void)testLowPowerModeOnOff {
    PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
    NSDictionary *onRule = @{ @"type": @"LowPowerMode", @"parameter": @"on" };
    NSDictionary *offRule = @{ @"type": @"LowPowerMode", @"parameter": @"off" };
    [source setBatteryPercentForTesting:50 lowPowerMode:YES];
    XCTAssertTrue([source doesRuleMatch:onRule]);
    XCTAssertFalse([source doesRuleMatch:offRule]);
    [source setBatteryPercentForTesting:50 lowPowerMode:NO];
    XCTAssertTrue([source doesRuleMatch:offRule]);
}

- (void)testTypesOfRulesMatchedIncludesBatteryAndLPM {
    PowerEvidenceSource *source = [[PowerEvidenceSource alloc] initForMatchingTests];
    NSArray *types = [source typesOfRulesMatched];
    XCTAssertTrue([types containsObject:@"Power"]);
    XCTAssertTrue([types containsObject:@"BatteryLevel"]);
    XCTAssertTrue([types containsObject:@"LowPowerMode"]);
}

@end
