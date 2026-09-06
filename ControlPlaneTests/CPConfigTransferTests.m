//
//  CPConfigTransferTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import "CPConfigTransfer.h"

@interface CPConfigTransferTests : XCTestCase
@end

@implementation CPConfigTransferTests

- (NSUserDefaults *)freshDefaults
{
    NSString *suiteName = [[NSUUID UUID] UUIDString];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    [defaults removePersistentDomainForName:suiteName];
    return defaults;
}

- (void)seedSampleConfigInDefaults:(NSUserDefaults *)defaults
{
    [defaults setObject:@[
        @{ @"uuid": @"ctx-home", @"name": @"Home", @"parentUUID": @"", @"icon": @"Home", @"iconColor": @"" }
    ] forKey:@"Contexts"];
    [defaults setObject:@[
        @{ @"type": @"Power", @"parameter": @"Battery", @"context": @"ctx-home", @"confidence": @0.8 }
    ] forKey:@"Rules"];
    [defaults setObject:@[
        @{ @"type": @"DefaultBrowser", @"parameter": @"Safari", @"context": @"ctx-home", @"when": @"Arrival", @"delay": @0 }
    ] forKey:@"Actions"];
    [defaults setDouble:0.8 forKey:@"MinimumConfidenceRequired"];
    [defaults setBool:YES forKey:@"EnableSwitchSmoothing"];
    [defaults setBool:YES forKey:@"EnablePowerEvidenceSource"];
    [defaults setBool:NO forKey:@"EnableBluetoothEvidenceSource"];
    [defaults setObject:@"ctx-home" forKey:@"DefaultContext"];
    [defaults setBool:YES forKey:@"UseDefaultContext"];
}

- (void)testSchemaVersionIsOne
{
    XCTAssertEqual(CPConfigTransferSchemaVersion, (NSInteger)1);
}

- (void)testExportIncludesSchemaVersionContextsRulesActionsAndSettings
{
    NSUserDefaults *defaults = [self freshDefaults];
    [self seedSampleConfigInDefaults:defaults];

    NSDictionary *doc = [CPConfigTransfer exportDictionaryFromDefaults:defaults];

    XCTAssertEqual([doc[@"schemaVersion"] integerValue], CPConfigTransferSchemaVersion);
    XCTAssertEqualObjects(doc[@"contexts"], [defaults arrayForKey:@"Contexts"]);
    XCTAssertEqualObjects(doc[@"rules"], [defaults arrayForKey:@"Rules"]);
    XCTAssertEqualObjects(doc[@"actions"], [defaults arrayForKey:@"Actions"]);

    NSDictionary *settings = doc[@"settings"];
    XCTAssertTrue([settings isKindOfClass:[NSDictionary class]]);
    XCTAssertEqualObjects(settings[@"MinimumConfidenceRequired"], @0.8);
    XCTAssertEqualObjects(settings[@"EnableSwitchSmoothing"], @YES);
    XCTAssertEqualObjects(settings[@"EnablePowerEvidenceSource"], @YES);
    XCTAssertEqualObjects(settings[@"EnableBluetoothEvidenceSource"], @NO);
    XCTAssertEqualObjects(settings[@"DefaultContext"], @"ctx-home");
    XCTAssertEqualObjects(settings[@"UseDefaultContext"], @YES);
}

- (void)testJSONRoundTripRestoresCleanDefaults
{
    NSUserDefaults *source = [self freshDefaults];
    [self seedSampleConfigInDefaults:source];

    NSError *exportError = nil;
    NSData *json = [CPConfigTransfer exportJSONDataFromDefaults:source error:&exportError];
    XCTAssertNil(exportError);
    XCTAssertNotNil(json);

    NSUserDefaults *dest = [self freshDefaults];
    // Confirm clean state
    XCTAssertNil([dest arrayForKey:@"Contexts"]);
    XCTAssertNil([dest arrayForKey:@"Rules"]);
    XCTAssertNil([dest arrayForKey:@"Actions"]);

    NSError *importError = nil;
    BOOL ok = [CPConfigTransfer importJSONData:json intoDefaults:dest error:&importError];
    XCTAssertTrue(ok);
    XCTAssertNil(importError);

    XCTAssertEqualObjects([dest arrayForKey:@"Contexts"], [source arrayForKey:@"Contexts"]);
    XCTAssertEqualObjects([dest arrayForKey:@"Rules"], [source arrayForKey:@"Rules"]);
    XCTAssertEqualObjects([dest arrayForKey:@"Actions"], [source arrayForKey:@"Actions"]);
    XCTAssertEqualWithAccuracy([dest doubleForKey:@"MinimumConfidenceRequired"], 0.8, 0.0001);
    XCTAssertTrue([dest boolForKey:@"EnableSwitchSmoothing"]);
    XCTAssertTrue([dest boolForKey:@"EnablePowerEvidenceSource"]);
    XCTAssertFalse([dest boolForKey:@"EnableBluetoothEvidenceSource"]);
    XCTAssertEqualObjects([dest stringForKey:@"DefaultContext"], @"ctx-home");
    XCTAssertTrue([dest boolForKey:@"UseDefaultContext"]);
}

- (void)testPropertyListRoundTripRestoresCleanDefaults
{
    NSUserDefaults *source = [self freshDefaults];
    [self seedSampleConfigInDefaults:source];

    NSError *exportError = nil;
    NSData *plist = [CPConfigTransfer exportPropertyListDataFromDefaults:source error:&exportError];
    XCTAssertNil(exportError);
    XCTAssertNotNil(plist);

    NSUserDefaults *dest = [self freshDefaults];
    NSError *importError = nil;
    BOOL ok = [CPConfigTransfer importPropertyListData:plist intoDefaults:dest error:&importError];
    XCTAssertTrue(ok);
    XCTAssertNil(importError);

    XCTAssertEqualObjects([dest arrayForKey:@"Contexts"], [source arrayForKey:@"Contexts"]);
    XCTAssertEqualObjects([dest arrayForKey:@"Rules"], [source arrayForKey:@"Rules"]);
    XCTAssertEqualObjects([dest arrayForKey:@"Actions"], [source arrayForKey:@"Actions"]);
}

- (void)testImportRejectsMissingSchemaVersion
{
    NSUserDefaults *defaults = [self freshDefaults];
    NSDictionary *bad = @{ @"contexts": @[], @"rules": @[], @"actions": @[], @"settings": @{} };
    NSError *error = nil;
    BOOL ok = [CPConfigTransfer importDictionary:bad intoDefaults:defaults error:&error];
    XCTAssertFalse(ok);
    XCTAssertEqual(error.code, CPConfigTransferErrorInvalidDocument);
}

- (void)testImportRejectsFutureSchemaVersion
{
    NSUserDefaults *defaults = [self freshDefaults];
    NSDictionary *future = @{
        @"schemaVersion": @(CPConfigTransferSchemaVersion + 1),
        @"contexts": @[],
        @"rules": @[],
        @"actions": @[],
        @"settings": @{}
    };
    NSError *error = nil;
    BOOL ok = [CPConfigTransfer importDictionary:future intoDefaults:defaults error:&error];
    XCTAssertFalse(ok);
    XCTAssertEqual(error.code, CPConfigTransferErrorUnsupportedSchemaVersion);
}

- (void)testImportReplacesExistingConfig
{
    NSUserDefaults *defaults = [self freshDefaults];
    [defaults setObject:@[ @{ @"uuid": @"old", @"name": @"Old" } ] forKey:@"Contexts"];
    [defaults setObject:@[ @{ @"type": @"USB", @"parameter": @"old" } ] forKey:@"Rules"];
    [defaults setObject:@[ @{ @"type": @"Mute", @"parameter": @"old" } ] forKey:@"Actions"];
    [defaults setDouble:0.1 forKey:@"MinimumConfidenceRequired"];

    NSDictionary *doc = @{
        @"schemaVersion": @(CPConfigTransferSchemaVersion),
        @"contexts": @[ @{ @"uuid": @"new", @"name": @"New" } ],
        @"rules": @[ @{ @"type": @"Power", @"parameter": @"AC" } ],
        @"actions": @[ @{ @"type": @"ShellScript", @"parameter": @"true" } ],
        @"settings": @{ @"MinimumConfidenceRequired": @0.9 }
    };

    NSError *error = nil;
    XCTAssertTrue([CPConfigTransfer importDictionary:doc intoDefaults:defaults error:&error]);
    XCTAssertNil(error);
    XCTAssertEqualObjects([defaults arrayForKey:@"Contexts"], doc[@"contexts"]);
    XCTAssertEqualObjects([defaults arrayForKey:@"Rules"], doc[@"rules"]);
    XCTAssertEqualObjects([defaults arrayForKey:@"Actions"], doc[@"actions"]);
    XCTAssertEqualWithAccuracy([defaults doubleForKey:@"MinimumConfidenceRequired"], 0.9, 0.0001);
}

@end
