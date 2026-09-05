//
//  WiFiRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "CoreWLANEvidenceSource.h"

@interface WiFiRuleMatchTests : XCTestCase
@end

@implementation WiFiRuleMatchTests

- (WiFiEvidenceSourceCoreWLAN *)sourceWithSSID:(NSString *)ssid
{
    WiFiEvidenceSourceCoreWLAN *source = [[WiFiEvidenceSourceCoreWLAN alloc] initForMatchingTests];
    [source setValue:@{ ssid: @YES } forKey:@"networkSSIDs"];
    [source setValue:@YES forKey:@"linkActive"];
    return source;
}

- (void)testSSIDMatch {
    WiFiEvidenceSourceCoreWLAN *source = [self sourceWithSSID:@"OfficeWiFi"];
    NSDictionary *rule = @{ @"type": @"WiFi SSID", @"parameter": @"OfficeWiFi" };
    XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testSSIDMiss {
    WiFiEvidenceSourceCoreWLAN *source = [self sourceWithSSID:@"OfficeWiFi"];
    NSDictionary *rule = @{ @"type": @"WiFi SSID", @"parameter": @"OtherSSID" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

@end
