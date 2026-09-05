//
//  InfoPlistPrivacyTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface InfoPlistPrivacyTests : XCTestCase
@end

@implementation InfoPlistPrivacyTests

- (NSDictionary *)shippingInfoPlist {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    XCTAssertNotNil(plist, @"Expected Info.plist at %@", path);
    return plist;
}

- (void)testLocationUsageDescriptionsPresent {
    NSDictionary *plist = [self shippingInfoPlist];
    XCTAssertNotNil(plist[@"NSLocationWhenInUseUsageDescription"]);
    XCTAssertNotNil(plist[@"NSLocationAlwaysAndWhenInUseUsageDescription"]);
}

- (void)testLocalNetworkAndBonjourKeysPresent {
    NSDictionary *plist = [self shippingInfoPlist];
    XCTAssertNotNil(plist[@"NSLocalNetworkUsageDescription"]);
    NSArray *services = plist[@"NSBonjourServices"];
    XCTAssertTrue([services isKindOfClass:[NSArray class]]);
    XCTAssertTrue([services containsObject:@"_services._dns-sd._udp"]);
}

- (void)testAppleEventsUsageDescriptionPresent {
    NSDictionary *plist = [self shippingInfoPlist];
    XCTAssertNotNil(plist[@"NSAppleEventsUsageDescription"]);
}

- (void)testBluetoothUsageDescriptionPresent {
    NSDictionary *plist = [self shippingInfoPlist];
    XCTAssertNotNil(plist[@"NSBluetoothAlwaysUsageDescription"]);
}

- (void)testATSDoesNotAllowArbitraryLoads {
    NSDictionary *plist = [self shippingInfoPlist];
    NSDictionary *ats = plist[@"NSAppTransportSecurity"];
    XCTAssertTrue([ats isKindOfClass:[NSDictionary class]]);
    XCTAssertNil(ats[@"NSAllowsArbitraryLoads"]);
    XCTAssertNotNil(ats[@"NSExceptionDomains"]);
}

@end
