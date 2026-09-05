//
//  PackedIPAddressTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "IPAddrEvidenceSource.h"

@interface PackedIPAddressTests : XCTestCase
@end

@implementation PackedIPAddressTests

- (void)testValidIPv4 {
    PackedIPv4Address *addr = [[PackedIPv4Address alloc] initWithString:@"192.168.1.10"];
    XCTAssertNotNil(addr);
    XCTAssertTrue(addr.inAddr != NULL);
}

- (void)testInvalidIPv4IsNil {
    XCTAssertNil([[PackedIPv4Address alloc] initWithString:@"not-an-ip"]);
    XCTAssertNil([[PackedIPv4Address alloc] initWithString:@"999.1.1.1"]);
}

- (void)testValidIPv6Loopback {
    PackedIPv6Address *addr = [[PackedIPv6Address alloc] initWithString:@"::1"];
    XCTAssertNotNil(addr);
}

- (void)testInvalidIPv6IsNil {
    XCTAssertNil([[PackedIPv6Address alloc] initWithString:@"gggg::1"]);
}

@end
