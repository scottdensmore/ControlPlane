//
//  CPLoginItemServiceTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import <ServiceManagement/ServiceManagement.h>
#import "CPLoginItemService.h"

@interface CPLoginItemServiceTests : XCTestCase
@end

@implementation CPLoginItemServiceTests

- (void)testCheckboxOnWhenEnabled {
    XCTAssertTrue([CPLoginItemService checkboxStateForStatus:SMAppServiceStatusEnabled]);
}

- (void)testCheckboxOnWhenRequiresApproval {
    XCTAssertTrue([CPLoginItemService checkboxStateForStatus:SMAppServiceStatusRequiresApproval]);
}

- (void)testCheckboxOffWhenNotRegistered {
    XCTAssertFalse([CPLoginItemService checkboxStateForStatus:SMAppServiceStatusNotRegistered]);
}

- (void)testCheckboxOffWhenNotFound {
    XCTAssertFalse([CPLoginItemService checkboxStateForStatus:SMAppServiceStatusNotFound]);
}

- (void)testSharedServiceReturnsStatusWithoutCrashing {
    SMAppServiceStatus status = [[CPLoginItemService sharedService] status];
    XCTAssertTrue(status == SMAppServiceStatusNotRegistered
                  || status == SMAppServiceStatusEnabled
                  || status == SMAppServiceStatusRequiresApproval
                  || status == SMAppServiceStatusNotFound);
}

@end
