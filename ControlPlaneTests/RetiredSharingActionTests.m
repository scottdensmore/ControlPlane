//
//  RetiredSharingActionTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "ToggleFTPAction.h"
#import "ToggleTFTPAction.h"
#import "ToggleWebSharingAction.h"

@interface RetiredSharingActionTests : XCTestCase
@end

@implementation RetiredSharingActionTests

- (void)testRetiredSharingActionsAreNotApplicable {
    XCTAssertFalse([ToggleFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleTFTPAction isActionApplicableToSystem]);
    XCTAssertFalse([ToggleWebSharingAction isActionApplicableToSystem]);
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

@end
