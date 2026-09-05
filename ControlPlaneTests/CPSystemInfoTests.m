//
//  CPSystemInfoTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "CPSystemInfo.h"

@interface CPSystemInfoTests : XCTestCase
@end

@implementation CPSystemInfoTests

- (void)testGetOSVersionMatchesProcessInfoEncoding {
    NSOperatingSystemVersion v = NSProcessInfo.processInfo.operatingSystemVersion;
    NSInteger expected = (v.majorVersion * 10 + v.minorVersion) * 10;
    // getOSVersion historically encodes major/minor only (patch ignored in formula used by app)
    NSInteger actual = [CPSystemInfo getOSVersion];
    // Allow either exact historical encoding or major*100+minor style drift — pin to implementation:
    // Source uses (major*10+minor)*10
    XCTAssertEqual(actual, expected);
}

- (void)testHardwareModelNonEmpty {
    NSString *model = [CPSystemInfo getHardwareModel];
    XCTAssertNotNil(model);
    XCTAssertGreaterThan(model.length, 0u);
}

@end
