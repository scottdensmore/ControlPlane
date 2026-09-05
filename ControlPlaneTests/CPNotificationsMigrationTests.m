//
//  CPNotificationsMigrationTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "CPNotifications.h"

@interface CPNotificationsMigrationTests : XCTestCase
@end

@implementation CPNotificationsMigrationTests

- (void)testMigratesEnableGrowlWhenEnableNotificationsMissing {
    NSString *suiteName = [[NSUUID UUID] UUIDString];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    [defaults removePersistentDomainForName:suiteName];
    [defaults setBool:YES forKey:@"EnableGrowl"];

    [CPNotifications migrateLegacyGrowlPreferenceInDefaults:defaults];

    XCTAssertTrue([defaults boolForKey:@"EnableNotifications"]);
    XCTAssertNil([defaults objectForKey:@"EnableGrowl"]);
}

- (void)testPreservesEnableNotificationsWhenBothKeysExist {
    NSString *suiteName = [[NSUUID UUID] UUIDString];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    [defaults removePersistentDomainForName:suiteName];
    [defaults setBool:NO forKey:@"EnableNotifications"];
    [defaults setBool:YES forKey:@"EnableGrowl"];

    [CPNotifications migrateLegacyGrowlPreferenceInDefaults:defaults];

    XCTAssertFalse([defaults boolForKey:@"EnableNotifications"]);
    XCTAssertNil([defaults objectForKey:@"EnableGrowl"]);
}

- (void)testNoOpWhenEnableGrowlAbsent {
    NSString *suiteName = [[NSUUID UUID] UUIDString];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    [defaults removePersistentDomainForName:suiteName];
    [defaults setBool:YES forKey:@"EnableNotifications"];

    [CPNotifications migrateLegacyGrowlPreferenceInDefaults:defaults];

    XCTAssertTrue([defaults boolForKey:@"EnableNotifications"]);
    XCTAssertNil([defaults objectForKey:@"EnableGrowl"]);
}

@end
