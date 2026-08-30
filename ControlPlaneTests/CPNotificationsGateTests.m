//
//  CPNotificationsGateTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "CPNotifications.h"

static NSUInteger CPNotificationsGateCallCount = 0;

@interface CPNotifications (GateTestSwizzle)
+ (void)cp_test_postNotification:(NSString *)title withMessage:(NSString *)message;
@end

@implementation CPNotifications (GateTestSwizzle)

+ (void)cp_test_postNotification:(NSString *)title withMessage:(NSString *)message {
    (void)title;
    (void)message;
    CPNotificationsGateCallCount += 1;
}

@end

@interface CPNotificationsGateTests : XCTestCase
@end

@implementation CPNotificationsGateTests {
    Method _original;
    Method _swizzle;
}

- (void)setUp {
    [super setUp];
    CPNotificationsGateCallCount = 0;
    _original = class_getClassMethod([CPNotifications class], @selector(postNotification:withMessage:));
    _swizzle = class_getClassMethod([CPNotifications class], @selector(cp_test_postNotification:withMessage:));
    method_exchangeImplementations(_original, _swizzle);
}

- (void)tearDown {
    method_exchangeImplementations(_original, _swizzle);
    [super tearDown];
}

- (void)testDisabledNotificationsDoNotPost {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"EnableNotifications"];
    [CPNotifications postUserNotification:@"Title" withMessage:@"Body"];
    XCTAssertEqual(CPNotificationsGateCallCount, 0u);
}

- (void)testEnabledNotificationsPost {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EnableNotifications"];
    [CPNotifications postUserNotification:@"Title" withMessage:@"Body"];
    XCTAssertEqual(CPNotificationsGateCallCount, 1u);
}

@end
