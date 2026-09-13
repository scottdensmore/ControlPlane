#import <XCTest/XCTest.h>
#import "CPSettingsReadModelTokens.h"

@interface CPSettingsReadModelTokensTests : XCTestCase
@end

@implementation CPSettingsReadModelTokensTests

- (void)testContextRowsPreserveOrderAndIds {
    NSArray *rows = [CPSettingsReadModelTokens contextRowsFromOrderedNames:@[ @"Home", @"Work" ]];
    XCTAssertEqual(rows.count, 2u);
    XCTAssertEqualObjects(rows[0][@"id"], @"Home");
    XCTAssertEqualObjects(rows[0][@"name"], @"Home");
    XCTAssertEqualObjects(rows[1][@"id"], @"Work");
}

- (void)testContextRowsIgnoreEmptyNames {
    NSArray *rows = [CPSettingsReadModelTokens contextRowsFromOrderedNames:@[ @"", @"Work", @"  " ]];
    XCTAssertEqual(rows.count, 1u);
    XCTAssertEqualObjects(rows[0][@"name"], @"Work");
}

- (void)testEvidenceRowsMapEnabledFlag {
    NSArray *rows = [CPSettingsReadModelTokens evidenceRowsFromDescriptors:@[
        @{ @"id": @"WiFi", @"name": @"Wi‑Fi", @"enabled": @YES },
        @{ @"id": @"Power", @"name": @"Power", @"enabled": @NO },
    ]];
    XCTAssertEqual(rows.count, 2u);
    XCTAssertEqualObjects(rows[0][@"enabled"], @YES);
    XCTAssertEqualObjects(rows[1][@"enabled"], @NO);
}

- (void)testActionTypeRowsPreserveTypeId {
    NSArray *rows = [CPSettingsReadModelTokens actionTypeRowsFromDescriptors:@[
        @{ @"id": @"DefaultBrowser", @"name": @"Default Browser" },
    ]];
    XCTAssertEqualObjects(rows[0][@"id"], @"DefaultBrowser");
    XCTAssertEqualObjects(rows[0][@"name"], @"Default Browser");
}

- (void)testEmptyInputsYieldEmptyArrays {
    XCTAssertEqual([CPSettingsReadModelTokens contextRowsFromOrderedNames:@[]].count, 0u);
    XCTAssertEqual([CPSettingsReadModelTokens evidenceRowsFromDescriptors:@[]].count, 0u);
    XCTAssertEqual([CPSettingsReadModelTokens actionTypeRowsFromDescriptors:nil].count, 0u);
}

@end
