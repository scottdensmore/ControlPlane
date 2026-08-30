//
//  ToggleableActionTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "MuteAction.h"

@interface ToggleableActionTests : XCTestCase
@end

@implementation ToggleableActionTests

- (void)testParameterNumberTrueTurnsOn {
    MuteAction *action = [[MuteAction alloc] initWithDictionary:@{
        @"type": @"Mute",
        @"parameter": @YES,
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    NSDictionary *dict = [action dictionary];
    XCTAssertEqualObjects(dict[@"parameter"], @YES);
}

- (void)testParameterStringOnTurnsOn {
    MuteAction *action = [[MuteAction alloc] initWithDictionary:@{
        @"type": @"Mute",
        @"parameter": @"on",
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    XCTAssertEqualObjects([action dictionary][@"parameter"], @YES);
}

- (void)testParameterStringZeroTurnsOff {
    MuteAction *action = [[MuteAction alloc] initWithDictionary:@{
        @"type": @"Mute",
        @"parameter": @"0",
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    XCTAssertEqualObjects([action dictionary][@"parameter"], @NO);
}

- (void)testLimitedOptionsHasOnAndOff {
    NSArray *options = [MuteAction limitedOptions];
    XCTAssertEqual(options.count, 2u);
}

@end
