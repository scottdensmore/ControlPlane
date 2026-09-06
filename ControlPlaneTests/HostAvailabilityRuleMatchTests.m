//
//  HostAvailabilityRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "HostAvailabilityEvidenceSource.h"

@interface HostAvailabilityRuleMatchTests : XCTestCase
@end

@implementation HostAvailabilityRuleMatchTests

- (void)testAvailableHostMatches
{
	HostAvailabilityEvidenceSource *source = [[HostAvailabilityEvidenceSource alloc] initForMatchingTests];
	[source setHost:@"office.example.com" available:YES];
	NSDictionary *rule = @{ @"parameter": @"office.example.com" };
	XCTAssertTrue([source doesRuleMatch:rule]);
}

- (void)testUnavailableHostDoesNotMatch
{
	HostAvailabilityEvidenceSource *source = [[HostAvailabilityEvidenceSource alloc] initForMatchingTests];
	[source setHost:@"office.example.com" available:NO];
	NSDictionary *rule = @{ @"parameter": @"office.example.com" };
	XCTAssertFalse([source doesRuleMatch:rule]);
}

- (void)testUnknownHostDoesNotMatch
{
	HostAvailabilityEvidenceSource *source = [[HostAvailabilityEvidenceSource alloc] initForMatchingTests];
	[source setHost:@"office.example.com" available:YES];
	NSDictionary *rule = @{ @"parameter": @"other.example.com" };
	XCTAssertFalse([source doesRuleMatch:rule]);
}

- (void)testEmptyParameterDoesNotMatch
{
	HostAvailabilityEvidenceSource *source = [[HostAvailabilityEvidenceSource alloc] initForMatchingTests];
	[source setHost:@"office.example.com" available:YES];
	NSDictionary *rule = @{ @"parameter": @"" };
	XCTAssertFalse([source doesRuleMatch:rule]);
}

@end
