//
//  CPDiagnosticsSnapshotTests.m
//  ControlPlaneTests
//
//  Characterization for Diagnostics pane snapshot (#35).
//

#import <XCTest/XCTest.h>
#import "CPDiagnosticsSnapshot.h"
#import "EvidenceSource.h"

@interface CPDiagnosticsSnapshotTests : XCTestCase
@end

@implementation CPDiagnosticsSnapshotTests

- (NSDictionary *)misSwitchFixtureSnapshot
{
    NSArray *rules = @[
        @{
            @"type": @"Power",
            @"description": @"On battery",
            @"parameter": @"Battery",
            @"context": @"ctx-home",
            @"confidence": @0.90,
            @"cachedStatus": @(RuleDoesMatch),
            @"negate": @0,
        },
        @{
            @"type": @"WiFi",
            @"description": @"Office SSID",
            @"parameter": @"Office",
            @"context": @"ctx-work",
            @"confidence": @0.55,
            @"cachedStatus": @(RuleDoesMatch),
            @"negate": @0,
        },
        @{
            @"type": @"USB",
            @"description": @"Dock",
            @"parameter": @"0x1234/0x5678",
            @"context": @"ctx-work",
            @"confidence": @0.80,
            @"cachedStatus": @(RuleDoesNotMatch),
            @"negate": @0,
        },
    ];

    NSDictionary *guesses = @{
        @"ctx-home": @0.90,
        @"ctx-work": @0.55,
    };

    NSArray *evidence = @[
        @{
            @"name": @"Power",
            @"friendlyName": @"Power",
            @"running": @YES,
            @"dataCollected": @YES,
            @"summary": @"Battery",
        },
        @{
            @"name": @"WiFi",
            @"friendlyName": @"WiFi",
            @"running": @YES,
            @"dataCollected": @YES,
            @"summary": @"Office",
        },
    ];

    return [CPDiagnosticsSnapshot snapshotWithCurrentContextName:@"Work"
                                              currentContextPath:@"Work"
                                              currentContextUUID:@"ctx-work"
                                                           rules:rules
                                                  contextGuesses:guesses
                                               contextNameForUUID:^NSString *(NSString *uuid) {
        if ([uuid isEqualToString:@"ctx-home"]) {
            return @"Home";
        }
        if ([uuid isEqualToString:@"ctx-work"]) {
            return @"Work";
        }
        return uuid;
    }
                                       minimumConfidenceRequired:0.75
                                                 evidenceSources:evidence];
}

- (void)testSnapshotExplainsMisSwitchedContextWinner
{
    NSDictionary *snap = [self misSwitchFixtureSnapshot];

    XCTAssertEqualObjects(snap[@"currentContextName"], @"Work");
    XCTAssertEqualObjects(snap[@"leadingContextName"], @"Home");
    XCTAssertEqualWithAccuracy([snap[@"leadingContextConfidence"] doubleValue], 0.90, 0.001);
    XCTAssertEqualWithAccuracy([snap[@"currentContextConfidence"] doubleValue], 0.55, 0.001);
    XCTAssertEqualWithAccuracy([snap[@"minimumConfidenceRequired"] doubleValue], 0.75, 0.001);

    NSString *explanation = snap[@"explanation"];
    XCTAssertTrue([explanation containsString:@"Home"], @"%@", explanation);
    XCTAssertTrue([explanation containsString:@"Work"], @"%@", explanation);
    XCTAssertTrue([explanation.lowercaseString containsString:@"confidence"] ||
                  [explanation containsString:@"%"],
                  @"Explanation should mention confidence: %@", explanation);
    XCTAssertTrue([explanation containsString:@"Power"] || [explanation containsString:@"battery"] ||
                  [explanation.lowercaseString containsString:@"battery"] ||
                  [explanation containsString:@"On battery"],
                  @"Explanation should cite the winning rule: %@", explanation);
}

- (void)testSnapshotIncludesPerRuleMatchAndContribution
{
    NSDictionary *snap = [self misSwitchFixtureSnapshot];
    NSArray *rows = snap[@"ruleRows"];
    XCTAssertEqual(rows.count, 3u);

    NSDictionary *powerRow = nil;
    NSDictionary *usbRow = nil;
    for (NSDictionary *row in rows) {
        if ([row[@"type"] isEqualToString:@"Power"]) {
            powerRow = row;
        }
        if ([row[@"type"] isEqualToString:@"USB"]) {
            usbRow = row;
        }
    }
    XCTAssertNotNil(powerRow);
    XCTAssertEqualObjects(powerRow[@"matchStatus"], @"match");
    XCTAssertEqualObjects(powerRow[@"contextName"], @"Home");
    XCTAssertEqualWithAccuracy([powerRow[@"ruleConfidence"] doubleValue], 0.90, 0.001);
    XCTAssertEqualWithAccuracy([powerRow[@"contextConfidence"] doubleValue], 0.90, 0.001);
    XCTAssertEqualObjects(powerRow[@"contributesToLeading"], @YES);

    XCTAssertNotNil(usbRow);
    XCTAssertEqualObjects(usbRow[@"matchStatus"], @"no-match");
    XCTAssertEqualObjects(usbRow[@"contributesToLeading"], @NO);
}

- (void)testSnapshotIncludesEvidenceAndCurrentContextPath
{
    NSDictionary *snap = [self misSwitchFixtureSnapshot];
    XCTAssertEqualObjects(snap[@"currentContextPath"], @"Work");

    NSArray *evidence = snap[@"evidenceSources"];
    XCTAssertEqual(evidence.count, 2u);
    XCTAssertEqualObjects(evidence[0][@"name"], @"Power");
    XCTAssertEqualObjects(evidence[0][@"summary"], @"Battery");
}

@end
