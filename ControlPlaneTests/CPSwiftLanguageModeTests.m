//
//  CPSwiftLanguageModeTests.m
//  ControlPlaneTests
//
//  Lock app SWIFT_VERSION = 6 (#200).
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPSwiftLanguageModeTests : XCTestCase
@end

@implementation CPSwiftLanguageModeTests

- (NSString *)projectText {
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *path = [root stringByAppendingPathComponent:@"ControlPlane.xcodeproj/project.pbxproj"];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(text.length > 0);
    return text;
}

- (void)testAppTargetSwiftVersionIsSix {
    NSString *project = [self projectText];
    // App Debug + Release both set SWIFT_VERSION (two occurrences today).
    NSRegularExpression *re =
        [NSRegularExpression regularExpressionWithPattern:@"SWIFT_VERSION = ([^;]+);"
                                                  options:0
                                                    error:NULL];
    NSArray<NSTextCheckingResult *> *matches =
        [re matchesInString:project options:0 range:NSMakeRange(0, project.length)];
    XCTAssertGreaterThanOrEqual(matches.count, 2u);
    for (NSTextCheckingResult *m in matches) {
        NSString *value = [project substringWithRange:[m rangeAtIndex:1]];
        XCTAssertEqualObjects(value, @"6",
                              @"App Swift sources must use SWIFT_VERSION = 6 (#200)");
    }
}

@end
