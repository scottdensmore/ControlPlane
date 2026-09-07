//
//  CPMockEvidenceJourneyTests.m
//  ControlPlaneTests
//
//  Injected evidence → confidence threshold → stubbed Mute / RunShortcut (#135).
//

#import <XCTest/XCTest.h>
#import "CPEvidenceSwitchJourney.h"
#import "PowerEvidenceSource.h"

@interface CPMockEvidenceJourneyTests : XCTestCase
@end

@implementation CPMockEvidenceJourneyTests

- (CPEvidenceSwitchJourney *)journeyWithHomeConfidence:(double)homeConfidence
{
    CPEvidenceSwitchJourney *journey = [[CPEvidenceSwitchJourney alloc] init];
    journey.minimumConfidenceRequired = 0.75;
    journey.currentContextUUID = @"ctx-work";
    journey.contexts = @[
        @{ @"uuid": @"ctx-home", @"name": @"Home" },
        @{ @"uuid": @"ctx-work", @"name": @"Work" },
    ];
    journey.rules = @[
        @{
            @"type": @"Power",
            @"parameter": @"Battery",
            @"context": @"ctx-home",
            @"confidence": @(homeConfidence),
            @"negate": @0,
        },
        @{
            @"type": @"Power",
            @"parameter": @"A/C",
            @"context": @"ctx-work",
            @"confidence": @0.40,
            @"negate": @0,
        },
    ];
    journey.actions = @[
        @{
            @"type": @"Mute",
            @"parameter": @YES,
            @"context": @"ctx-home",
            @"when": @"Arrival",
            @"enabled": @YES,
            @"delay": @0,
        },
        @{
            @"type": @"RunShortcut",
            @"parameter": @"CP Test Notify",
            @"context": @"ctx-home",
            @"when": @"Departure",
            @"enabled": @YES,
            @"delay": @0,
        },
    ];
    return journey;
}

- (void)testInjectedBatteryEvidenceSwitchesContextAndStubsMute
{
    CPEvidenceSwitchJourney *journey = [self journeyWithHomeConfidence:0.90];
    NSMutableArray<NSString *> *executedTypes = [NSMutableArray array];

    PowerEvidenceSource *power = [[PowerEvidenceSource alloc] initForMatchingTests];
    [power setPowerStatusForTesting:@"Battery"];
    journey.evidenceMatcher = ^BOOL(NSDictionary *rule) {
        return [power doesRuleMatch:rule];
    };
    journey.actionExecutor = ^BOOL(NSDictionary *action, NSString **error) {
        (void)error;
        [executedTypes addObject:action[@"type"]];
        return YES;
    };

    XCTAssertTrue([journey evaluate]);
    XCTAssertEqualObjects(journey.activeContextUUID, @"ctx-home");
    XCTAssertEqualWithAccuracy([journey.lastGuesses[@"ctx-home"] doubleValue], 0.90, 0.001);
    XCTAssertEqualObjects(executedTypes, @[ @"Mute" ]);
    XCTAssertEqualObjects(journey.executedActions.firstObject[@"parameter"], @YES);
}

- (void)testInjectEvidenceAPIBelowThresholdDoesNotSwitchOrRunActions
{
    CPEvidenceSwitchJourney *journey = [self journeyWithHomeConfidence:0.50];
    __block NSUInteger executions = 0;
    journey.actionExecutor = ^BOOL(NSDictionary *action, NSString **error) {
        (void)action;
        (void)error;
        executions += 1;
        return YES;
    };

    [journey injectEvidenceWithType:@"Power" parameter:@"Battery"];

    XCTAssertFalse([journey evaluate]);
    XCTAssertNil(journey.activeContextUUID);
    XCTAssertEqualObjects(journey.currentContextUUID, @"ctx-work");
    XCTAssertEqual(executions, 0u);
    XCTAssertEqual(journey.executedActions.count, 0u);
    XCTAssertLessThan([journey.lastGuesses[@"ctx-home"] doubleValue], journey.minimumConfidenceRequired);
}

- (void)testAlreadyActiveContextDoesNotRerunArrivalStub
{
    CPEvidenceSwitchJourney *journey = [self journeyWithHomeConfidence:0.90];
    journey.currentContextUUID = @"ctx-home";
    [journey injectEvidenceWithType:@"Power" parameter:@"Battery"];

    XCTAssertFalse([journey evaluate]);
    XCTAssertEqual(journey.executedActions.count, 0u);
}

- (void)testRunShortcutArrivalIsRecordedWithoutLaunchingCLI
{
    CPEvidenceSwitchJourney *journey = [self journeyWithHomeConfidence:0.90];
    journey.actions = @[
        @{
            @"type": @"RunShortcut",
            @"parameter": @"CP Test Notify",
            @"context": @"ctx-home",
            @"when": @"Arrival",
            @"enabled": @YES,
        },
    ];

    NSMutableArray<NSString *> *parameters = [NSMutableArray array];
    journey.actionExecutor = ^BOOL(NSDictionary *action, NSString **error) {
        (void)error;
        XCTAssertEqualObjects(action[@"type"], @"RunShortcut");
        [parameters addObject:action[@"parameter"]];
        return YES;
    };

    [journey injectEvidenceWithType:@"Power" parameter:@"Battery"];

    XCTAssertTrue([journey evaluate]);
    XCTAssertEqualObjects(parameters, @[ @"CP Test Notify" ]);
}

@end
