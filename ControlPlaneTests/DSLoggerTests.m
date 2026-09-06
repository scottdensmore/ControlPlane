//
//  DSLoggerTests.m
//  ControlPlaneTests
//
//  Characterization for unified logging subsystem / categories (#35).
//

#import <XCTest/XCTest.h>
#import "DSLogger.h"

@interface DSLoggerTests : XCTestCase
@end

@implementation DSLoggerTests

- (void)testUnifiedLoggingSubsystemString
{
    XCTAssertEqualObjects([DSLogger unifiedLoggingSubsystem], @"com.scottdensmore.ControlPlane");
}

- (void)testCategoryConstants
{
    XCTAssertEqualObjects(DSLoggerCategoryEvidence, @"Evidence");
    XCTAssertEqualObjects(DSLoggerCategoryRules, @"Rules");
    XCTAssertEqualObjects(DSLoggerCategoryActions, @"Actions");
    XCTAssertEqualObjects(DSLoggerCategoryHelper, @"Helper");
    XCTAssertEqualObjects(DSLoggerCategoryGeneral, @"General");
}

- (void)testRingBufferStillCapturesCategorizedLogs
{
    DSLogger *logger = [DSLogger sharedLogger];
    XCTAssertNotNil(logger);

    NSString *marker = [NSString stringWithFormat:@"diag-logger-test-%@", [[NSUUID UUID] UUIDString]];
    [DSLogger logFromFunction:@"DSLoggerTests" category:DSLoggerCategoryRules withInfo:marker];

    // Async hop onto the logger queue; give it a moment.
    XCTestExpectation *exp = [self expectationWithDescription:@"ring buffer update"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    NSString *buf = [logger buffer];
    XCTAssertTrue([buf containsString:marker], @"Expected ring buffer to contain %@", marker);
}

@end
