//
//  USBRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "USBEvidenceSource.h"

@interface USBRuleMatchTests : XCTestCase
@end

@implementation USBRuleMatchTests

- (USBEvidenceSource *)sourceWithDeviceVendor:(int)vendor product:(int)product
{
    USBEvidenceSource *source = [[USBEvidenceSource alloc] initForMatchingTests];
    [source setValue:[NSMutableArray arrayWithObject:@{
        @"vendor_id": @(vendor),
        @"product_id": @(product)
    }] forKey:@"devices"];
    return source;
}

- (void)testVendorProductMatch {
    USBEvidenceSource *source = [self sourceWithDeviceVendor:1452 product:640];
    NSDictionary *rule = @{ @"parameter": @"1452,640" };
    XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testVendorProductMiss {
    USBEvidenceSource *source = [self sourceWithDeviceVendor:1452 product:640];
    NSDictionary *rule = @{ @"parameter": @"1452,641" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

@end
