//
//  RetiredSharingActionTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "ToggleFTPAction.h"
#import "ToggleTFTPAction.h"
#import "ToggleWebSharingAction.h"
#import "ToggleInternetSharingAction.h"
#import "ToggleFileSharingAction.h"

@interface RetiredSharingActionTests : XCTestCase
@end

@implementation RetiredSharingActionTests

- (void)testRetiredSharingActionsAreNotApplicable {
    XCTAssertFalse([ToggleFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleTFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleWebSharingAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleInternetSharingAction isActionApplicableToSystem]);
}

- (void)testFileSharingLimitedOptionsAreSMBOnly {
    NSArray *options = [ToggleFileSharingAction limitedOptions];
    XCTAssertEqual(options.count, 2u);
    for (NSDictionary *entry in options) {
        NSNumber *option = entry[@"option"];
        XCTAssertFalse([ToggleFileSharingAction parameterRequiresAFP:option]);
    }
}

- (void)testLegacyAFPFileSharingActionFailsWithoutHelper {
    ToggleFileSharingAction *action = [[ToggleFileSharingAction alloc] initWithDictionary:@{
        @"type": @"ToggleFileSharing",
        @"parameter": @(kCPAFPEnable),
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"AFP"].location != NSNotFound);
}

- (void)testLegacyFTPActionFailsWithoutHelper {
    ToggleFTPAction *action = [[ToggleFTPAction alloc] initWithOption:@YES];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"FTP"].location != NSNotFound);
}

- (void)testLegacyTFTPActionFailsWithoutHelper {
    ToggleTFTPAction *action = [[ToggleTFTPAction alloc] initWithOption:@NO];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"TFTP"].location != NSNotFound);
}

- (void)testLegacyWebSharingActionFailsWithoutHelper {
    ToggleWebSharingAction *action = [[ToggleWebSharingAction alloc] initWithOption:@YES];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"Web sharing"].location != NSNotFound);
}

- (void)testLegacyInternetSharingActionFailsWithoutHelper {
    ToggleInternetSharingAction *action = [[ToggleInternetSharingAction alloc] initWithOption:@YES];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"Internet Sharing"].location != NSNotFound);
}

@end
