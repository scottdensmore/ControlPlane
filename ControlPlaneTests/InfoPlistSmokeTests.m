//
//  InfoPlistSmokeTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>

@interface InfoPlistSmokeTests : XCTestCase
@end

@implementation InfoPlistSmokeTests

- (NSDictionary *)infoDictionary {
    NSBundle *bundle = [NSBundle mainBundle];
    XCTAssertNotNil(bundle);
    return bundle.infoDictionary;
}

- (void)testBundleIdentifier {
    NSString *bid = self.infoDictionary[@"CFBundleIdentifier"];
    XCTAssertTrue([bid containsString:@"ControlPlane"] || [bid containsString:@"scottdensmore"]);
}

- (void)testIsAgentApp {
    // LSUIElement may be string "1" or boolean
    id value = self.infoDictionary[@"LSUIElement"];
    XCTAssertNotNil(value);
    BOOL isAgent = NO;
    if ([value isKindOfClass:[NSNumber class]]) {
        isAgent = [value boolValue];
    } else if ([value isKindOfClass:[NSString class]]) {
        isAgent = [value isEqualToString:@"1"] || [[value lowercaseString] isEqualToString:@"true"];
    }
    XCTAssertTrue(isAgent);
}

- (void)testBluetoothUsageDescriptionPresent {
    XCTAssertNotNil(self.infoDictionary[@"NSBluetoothAlwaysUsageDescription"]);
}

@end
