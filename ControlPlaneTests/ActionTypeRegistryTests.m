//
//  ActionTypeRegistryTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "Action.h"
#import "MuteAction.h"
#import "ToggleFTPAction.h"

@interface ActionTypeRegistryTests : XCTestCase
@end

@implementation ActionTypeRegistryTests

- (void)testTypeForKnownActionClass {
    XCTAssertEqualObjects([Action typeForClass:[MuteAction class]], @"Mute");
}

- (void)testClassForKnownType {
    XCTAssertEqualObjects([Action classForType:@"Mute"], [MuteAction class]);
    XCTAssertEqualObjects([Action classForType:@"ToggleFTP"], [ToggleFTPAction class]);
}

- (void)testClassForUnknownTypeIsNil {
    XCTAssertNil([Action classForType:@"NotARealActionType"]);
}

- (void)testActionFromDictionaryRequiresType {
    XCTAssertNil([Action actionFromDictionary:@{}]);
}

- (void)testActionFromDictionaryCreatesMute {
    MuteAction *action = (MuteAction *)[Action actionFromDictionary:@{
        @"type": @"Mute",
        @"parameter": @YES,
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    XCTAssertNotNil(action);
    XCTAssertTrue([action isKindOfClass:[MuteAction class]]);
    NSDictionary *roundTrip = [action dictionary];
    XCTAssertEqualObjects(roundTrip[@"type"], @"Mute");
    XCTAssertEqualObjects(roundTrip[@"parameter"], @YES);
}

@end
