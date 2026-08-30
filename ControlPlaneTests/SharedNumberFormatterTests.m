//
//  SharedNumberFormatterTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "SharedNumberFormatter.h"

@interface SharedNumberFormatterTests : XCTestCase
@end

@implementation SharedNumberFormatterTests

- (void)testPercentStyleFormatterIsSingleton {
    NSNumberFormatter *a = [SharedNumberFormatter percentStyleFormatter];
    NSNumberFormatter *b = [SharedNumberFormatter percentStyleFormatter];
    XCTAssertNotNil(a);
    XCTAssertEqual(a, b);
    XCTAssertEqual(a.numberStyle, NSNumberFormatterPercentStyle);
}

- (void)testFormatsConfidenceLikeUI {
    NSNumberFormatter *fmt = [SharedNumberFormatter percentStyleFormatter];
    NSString *text = [fmt stringFromNumber:@0.75];
    XCTAssertNotNil(text);
    XCTAssertTrue([text containsString:@"75"] || [text containsString:@"0.75"] || [text containsString:@"75%"]);
}

@end
