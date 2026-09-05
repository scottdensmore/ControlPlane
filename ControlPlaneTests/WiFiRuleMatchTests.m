//
//  WiFiRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
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

- (void)testEmptySSIDCollectionDoesNotMatchWhenLocationWouldDeny {
    // Characterization: with no collected SSIDs (Tahoe Location-denied path), rules must miss, not crash.
    WiFiEvidenceSourceCoreWLAN *source = [[WiFiEvidenceSourceCoreWLAN alloc] initForMatchingTests];
    [source setValue:nil forKey:@"networkSSIDs"];
    [source setValue:nil forKey:@"networkBSSIDs"];
    [source setValue:@YES forKey:@"linkActive"];

    NSDictionary *ssidRule = @{ @"type": @"WiFi SSID", @"parameter": @"OfficeWiFi" };
    NSDictionary *bssidRule = @{ @"type": @"WiFi BSSID", @"parameter": @"aa:bb:cc:dd:ee:ff" };
    XCTAssertFalse([source doesRuleMatch:ssidRule]);
    XCTAssertFalse([source doesRuleMatch:bssidRule]);
}

- (void)testLocationDeniedStatusIsDetected {
    XCTAssertTrue([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationDeniedOrRestricted:kCLAuthorizationStatusDenied]);
    XCTAssertTrue([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationDeniedOrRestricted:kCLAuthorizationStatusRestricted]);
    XCTAssertFalse([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationDeniedOrRestricted:kCLAuthorizationStatusNotDetermined]);
    XCTAssertFalse([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationDeniedOrRestricted:kCLAuthorizationStatusAuthorizedAlways]);
}

- (void)testLocationGrantedStatusIsDetected {
    XCTAssertTrue([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationGranted:kCLAuthorizationStatusAuthorizedAlways]);
    XCTAssertFalse([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationGranted:kCLAuthorizationStatusDenied]);
    XCTAssertFalse([WiFiEvidenceSourceCoreWLAN isLocationAuthorizationGranted:kCLAuthorizationStatusNotDetermined]);
}

- (void)testSSIDUnavailableGuidanceMentionsLocation {
    NSString *message = [WiFiEvidenceSourceCoreWLAN ssidUnavailableDueToLocationAuthorizationMessage];
    XCTAssertTrue([message rangeOfString:@"Location" options:NSCaseInsensitiveSearch].location != NSNotFound);
    XCTAssertTrue([message rangeOfString:@"Wi" options:NSCaseInsensitiveSearch].location != NSNotFound);
    XCTAssertTrue([message rangeOfString:@"System Settings" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (void)testDescriptionMentionsLocationRequirement {
    WiFiEvidenceSourceCoreWLAN *source = [[WiFiEvidenceSourceCoreWLAN alloc] initForMatchingTests];
    NSString *description = [source description];
    XCTAssertTrue([description rangeOfString:@"Location" options:NSCaseInsensitiveSearch].location != NSNotFound,
                  @"Evidence Sources prefs tip must mention Location for Wi‑Fi SSID");
}

@end
