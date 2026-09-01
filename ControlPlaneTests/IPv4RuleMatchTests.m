//
//  IPv4RuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "IPAddrEvidenceSource.h"
#import "IPv4RuleType.h"

@interface IPv4RuleMatchTests : XCTestCase
@end

@implementation IPv4RuleMatchTests

- (IPAddrEvidenceSource *)sourceWithAddress:(NSString *)ip {
    IPAddrEvidenceSource *source = [[IPAddrEvidenceSource alloc] initForMatchingTests];
    PackedIPv4Address *packed = [[PackedIPv4Address alloc] initWithString:ip];
    XCTAssertNotNil(packed);
    [source setValue:@[packed] forKey:@"packedIPv4Addresses"];
    [source setValue:@[ip] forKey:@"stringIPv4Addresses"];
    return source;
}

- (void)testSubnetMatch {
    IPAddrEvidenceSource *source = [self sourceWithAddress:@"192.168.1.50"];
    IPv4RuleType *ruleType = [[IPv4RuleType alloc] initWithEvidenceSource:source matchingOnly:YES];
    NSMutableDictionary *rule = [@{
        @"parameter": @"192.168.1.0,255.255.255.0"
    } mutableCopy];
    XCTAssertTrue([ruleType doesRuleMatch:rule]);
}

- (void)testSubnetMiss {
    IPAddrEvidenceSource *source = [self sourceWithAddress:@"10.0.0.5"];
    IPv4RuleType *ruleType = [[IPv4RuleType alloc] initWithEvidenceSource:source matchingOnly:YES];
    NSMutableDictionary *rule = [@{
        @"parameter": @"192.168.1.0,255.255.255.0"
    } mutableCopy];
    XCTAssertFalse([ruleType doesRuleMatch:rule]);
}

- (void)testCorruptParameterDoesNotMatch {
    IPAddrEvidenceSource *source = [self sourceWithAddress:@"192.168.1.50"];
    IPv4RuleType *ruleType = [[IPv4RuleType alloc] initWithEvidenceSource:source matchingOnly:YES];
    NSMutableDictionary *rule = [@{ @"parameter": @"bad" } mutableCopy];
    XCTAssertFalse([ruleType doesRuleMatch:rule]);
}

@end
