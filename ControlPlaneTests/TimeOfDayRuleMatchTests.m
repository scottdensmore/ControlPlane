//
//  TimeOfDayRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "TimeOfDayEvidenceSource.h"

@interface TimeOfDayRuleMatchTests : XCTestCase
@end

@implementation TimeOfDayRuleMatchTests

- (void)setUp {
    [super setUp];
    [TimeOfDayEvidenceSource clearNowForTesting];
}

- (void)tearDown {
    [TimeOfDayEvidenceSource clearNowForTesting];
    [super tearDown];
}

- (NSDate *)dateOnWeekday:(NSInteger)weekday hour:(NSInteger)hour minute:(NSInteger)minute
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 2026;
    components.month = 3;
    components.day = 3; // Tuesday
    components.hour = hour;
    components.minute = minute;
    components.second = 0;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateFromComponents:components];
    NSInteger actualWeekday = [calendar component:NSCalendarUnitWeekday fromDate:date];
    if (actualWeekday != weekday) {
        components.day += (weekday - actualWeekday + 7) % 7;
        date = [calendar dateFromComponents:components];
    }
    return date;
}

- (void)testWeekdayWindowMatch {
    TimeOfDayEvidenceSource *source = [[TimeOfDayEvidenceSource alloc] initForMatchingTests];
    NSDate *now = [self dateOnWeekday:3 hour:10 minute:30]; // Tuesday 10:30
    [TimeOfDayEvidenceSource setNowForTesting:now];

    NSDictionary *rule = @{ @"parameter": @"Weekday,09:00,17:00" };
    XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testWeekdayWindowMissOutsideHours {
    TimeOfDayEvidenceSource *source = [[TimeOfDayEvidenceSource alloc] initForMatchingTests];
    NSDate *now = [self dateOnWeekday:3 hour:20 minute:0];
    [TimeOfDayEvidenceSource setNowForTesting:now];

    NSDictionary *rule = @{ @"parameter": @"Weekday,09:00,17:00" };
    XCTAssertFalse([source doesRuleMatch:rule]);
}

@end
