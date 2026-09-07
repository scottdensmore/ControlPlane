//
//  DisplayCountRuleMatchTests.m
//  ControlPlaneTests
//
//  Display count and arrangement fingerprint matching (#132).
//

#import <XCTest/XCTest.h>
#import "MonitorEvidenceSource.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface DisplayCountRuleMatchTests : XCTestCase
@end

@implementation DisplayCountRuleMatchTests

- (NSDictionary *)builtinAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height scale:(CGFloat)scale
{
    return @{
        @"x": @(x),
        @"y": @(y),
        @"width": @(width),
        @"height": @(height),
        @"builtin": @YES,
        @"scale": @(scale),
    };
}

- (NSDictionary *)externalAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height scale:(CGFloat)scale
{
    return @{
        @"x": @(x),
        @"y": @(y),
        @"width": @(width),
        @"height": @(height),
        @"builtin": @NO,
        @"scale": @(scale),
    };
}

- (void)testAtDeskRuleMatchesTwoOrMoreDisplays
{
    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    [source setDisplayDescriptorsForTesting:@[
        [self builtinAtX:0 y:0 width:1512 height:982 scale:2],
        [self externalAtX:1512 y:0 width:1920 height:1080 scale:1],
    ]];

    NSDictionary *atDesk = @{ @"type": @"DisplayCount", @"parameter": @">=2" };
    NSDictionary *exactlyOne = @{ @"type": @"DisplayCount", @"parameter": @"==1" };
    XCTAssertTrue([source doesRuleMatch:atDesk]);
    XCTAssertFalse([source doesRuleMatch:exactlyOne]);
}

- (void)testDisplayCountAcceptsUnicodeAndExternalScope
{
    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    [source setDisplayDescriptorsForTesting:@[
        [self builtinAtX:0 y:0 width:1512 height:982 scale:2],
        [self externalAtX:1512 y:-100 width:1920 height:1080 scale:2],
        [self externalAtX:1512 y:980 width:1920 height:1080 scale:1],
    ]];

    NSString *unicodeAtLeastTwo = [NSString stringWithFormat:@"%C2", (unichar)0x2265];
    NSDictionary *unicodeRule = @{ @"type": @"DisplayCount", @"parameter": unicodeAtLeastTwo };
    NSDictionary *totalAtLeastThree = @{ @"type": @"DisplayCount", @"parameter": @"total>=3" };
    NSDictionary *twoExternal = @{ @"type": @"DisplayCount", @"parameter": @"external>=2" };
    NSDictionary *noExternal = @{ @"type": @"DisplayCount", @"parameter": @"external==0" };
    NSDictionary *threeExternal = @{ @"type": @"DisplayCount", @"parameter": @"external>=3" };
    XCTAssertTrue([source doesRuleMatch:unicodeRule]);
    XCTAssertTrue([source doesRuleMatch:totalAtLeastThree]);
    XCTAssertTrue([source doesRuleMatch:twoExternal]);
    XCTAssertFalse([source doesRuleMatch:noExternal]);
    XCTAssertFalse([source doesRuleMatch:threeExternal]);
}

- (void)testLaptopOnlyMatchesNoExternalDisplays
{
    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    [source setDisplayDescriptorsForTesting:@[
        [self builtinAtX:0 y:0 width:1512 height:982 scale:2],
    ]];

    NSDictionary *noExternal = @{ @"type": @"DisplayCount", @"parameter": @"external==0" };
    NSDictionary *exactlyOne = @{ @"type": @"DisplayCount", @"parameter": @"==1" };
    NSDictionary *atDesk = @{ @"type": @"DisplayCount", @"parameter": @">=2" };
    NSDictionary *oneExternal = @{ @"type": @"DisplayCount", @"parameter": @"external>=1" };
    XCTAssertTrue([source doesRuleMatch:noExternal]);
    XCTAssertTrue([source doesRuleMatch:exactlyOne]);
    XCTAssertFalse([source doesRuleMatch:atDesk]);
    XCTAssertFalse([source doesRuleMatch:oneExternal]);
}

- (void)testUnknownCountDoesNotMatch
{
    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    NSDictionary *atDesk = @{ @"type": @"DisplayCount", @"parameter": @">=2" };
    NSDictionary *noExternal = @{ @"type": @"DisplayCount", @"parameter": @"external==0" };
    NSDictionary *invalid = @{ @"type": @"DisplayCount", @"parameter": @"not-a-rule" };
    XCTAssertFalse([source doesRuleMatch:atDesk]);
    XCTAssertFalse([source doesRuleMatch:noExternal]);
    XCTAssertFalse([source doesRuleMatch:invalid]);
}

- (void)testArrangementFingerprintIsStableAndTranslationInvariant
{
    NSArray *desk = @[
        [self externalAtX:1512 y:0 width:1920 height:1080 scale:1],
        [self builtinAtX:0 y:0 width:1512 height:982 scale:2],
    ];
    NSArray *sameOrderDifferentOrigin = @[
        [self builtinAtX:100 y:40 width:1512 height:982 scale:2],
        [self externalAtX:1612 y:40 width:1920 height:1080 scale:1],
    ];
    NSArray *movedExternal = @[
        [self builtinAtX:0 y:0 width:1512 height:982 scale:2],
        [self externalAtX:0 y:-1080 width:1920 height:1080 scale:1],
    ];

    NSString *first = [MonitorEvidenceSource arrangementFingerprintForDisplayDescriptors:desk];
    NSString *reordered = [MonitorEvidenceSource arrangementFingerprintForDisplayDescriptors:@[
        desk[1],
        desk[0],
    ]];
    NSString *translated = [MonitorEvidenceSource arrangementFingerprintForDisplayDescriptors:sameOrderDifferentOrigin];
    NSString *rearranged = [MonitorEvidenceSource arrangementFingerprintForDisplayDescriptors:movedExternal];

    XCTAssertGreaterThan(first.length, 0u);
    XCTAssertEqualObjects(first, reordered);
    XCTAssertEqualObjects(first, translated);
    XCTAssertNotEqualObjects(first, rearranged);
}

- (void)testArrangementRuleMatchesInjectedFingerprint
{
    NSArray *desk = @[
        [self builtinAtX:0 y:0 width:1512 height:982 scale:2],
        [self externalAtX:1512 y:0 width:1920 height:1080 scale:1],
    ];
    NSString *fingerprint = [MonitorEvidenceSource arrangementFingerprintForDisplayDescriptors:desk];

    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    [source setDisplayDescriptorsForTesting:desk];

    NSDictionary *currentArrangement = @{ @"type": @"DisplayArrangement", @"parameter": fingerprint };
    NSDictionary *otherArrangement = @{ @"type": @"DisplayArrangement", @"parameter": @"other-layout" };
    XCTAssertTrue([source doesRuleMatch:currentArrangement]);
    XCTAssertFalse([source doesRuleMatch:otherArrangement]);

    NSArray *suggestions = [source getSuggestions];
    BOOL foundArrangement = NO;
    BOOL foundAtDesk = NO;
    for (NSDictionary *suggestion in suggestions) {
        if ([suggestion[@"type"] isEqualToString:@"DisplayArrangement"] &&
            [suggestion[@"parameter"] isEqualToString:fingerprint]) {
            foundArrangement = YES;
        }
        NSString *atDeskParameter = [@">" stringByAppendingString:@"=2"];
        if ([suggestion[@"type"] isEqualToString:@"DisplayCount"] &&
            [suggestion[@"parameter"] isEqualToString:atDeskParameter]) {
            foundAtDesk = YES;
        }
    }
    XCTAssertTrue(foundArrangement);
    XCTAssertTrue(foundAtDesk);
}

- (void)testLegacyMonitorSerialRulesStillMatch
{
    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    [source setMonitorsForTesting:@[
        @{ @"serial": @"19501", @"name": @"DELL 1907FP" },
    ]];
    NSDictionary *namedMonitor = @{ @"type": @"Monitor", @"parameter": @"19501" };
    NSDictionary *legacyMonitor = @{ @"parameter": @"19501" };
    NSDictionary *otherMonitor = @{ @"type": @"Monitor", @"parameter": @"1" };
    XCTAssertTrue([source doesRuleMatch:namedMonitor]);
    XCTAssertTrue([source doesRuleMatch:legacyMonitor]);
    XCTAssertFalse([source doesRuleMatch:otherMonitor]);
}

- (void)testTypesOfRulesIncludeCountAndArrangement
{
    MonitorEvidenceSource *source = [[MonitorEvidenceSource alloc] initForMatchingTests];
    NSArray *types = [source typesOfRulesMatched];
    XCTAssertTrue([types containsObject:@"Monitor"]);
    XCTAssertTrue([types containsObject:@"DisplayCount"]);
    XCTAssertTrue([types containsObject:@"DisplayArrangement"]);
}

- (void)testHelpDocumentsDisplayCountAndPublicAPIs
{
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:@"Resources/ControlPlane Help/pages/evidencesources.html"];
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue([html rangeOfString:@"display count" options:NSCaseInsensitiveSearch].location != NSNotFound);
    XCTAssertTrue([html rangeOfString:@"NSScreen"].location != NSNotFound);
    XCTAssertTrue([html rangeOfString:@"arrangement" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (void)testMonitorSourceAvoidsPrivateWindowServerAPIs
{
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *path = [root stringByAppendingPathComponent:@"Source/MonitorEvidenceSource.m"];
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(source);
    XCTAssertTrue([source containsString:@"NSScreen"] || [source containsString:@"CGDisplay"]);
    for (NSString *forbidden in @[ @"WindowServer", @"SkyLight", @"CGSGet", @"SLSGet" ]) {
        XCTAssertFalse([source containsString:forbidden], @"Monitor evidence must stay on public display APIs (%@)", forbidden);
    }
}

@end
