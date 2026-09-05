//
//  ContextModelTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "ContextsDataSource.h"

@interface ContextModelTests : XCTestCase
@end

@implementation ContextModelTests

- (void)testNewContextHasUUIDAndIsRoot {
    Context *ctx = [[Context alloc] init];
    XCTAssertNotNil(ctx.uuid);
    XCTAssertGreaterThan(ctx.uuid.length, 0u);
    XCTAssertTrue([ctx isRoot]);
}

- (void)testDictionaryRoundTripPreservesName {
    Context *ctx = [[Context alloc] init];
    ctx.name = @"Work";
    NSDictionary *dict = [ctx dictionary];
    Context *restored = [[Context alloc] initWithDictionary:dict];
    XCTAssertEqualObjects(restored.name, @"Work");
    XCTAssertEqualObjects(restored.uuid, ctx.uuid);
}

@end
