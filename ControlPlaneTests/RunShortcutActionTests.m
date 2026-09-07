//
//  RunShortcutActionTests.m
//  ControlPlaneTests
//
//  #34 Milestone A — Run Shortcut action registration / applicability.
//

#import <XCTest/XCTest.h>
#import "Action.h"
#import "RunShortcutAction.h"

@interface RunShortcutActionTests : XCTestCase
@end

@implementation RunShortcutActionTests

- (void)testTypeForClass {
    XCTAssertEqualObjects([Action typeForClass:[RunShortcutAction class]], @"RunShortcut");
}

- (void)testClassForType {
    XCTAssertEqualObjects([Action classForType:@"RunShortcut"], [RunShortcutAction class]);
}

- (void)testActionFromDictionaryRoundTrip {
    RunShortcutAction *action = (RunShortcutAction *)[Action actionFromDictionary:@{
        @"type": @"RunShortcut",
        @"parameter": @"Enable Work Focus",
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    XCTAssertNotNil(action);
    XCTAssertTrue([action isKindOfClass:[RunShortcutAction class]]);
    NSDictionary *roundTrip = [action dictionary];
    XCTAssertEqualObjects(roundTrip[@"type"], @"RunShortcut");
    XCTAssertEqualObjects(roundTrip[@"parameter"], @"Enable Work Focus");
}

- (void)testApplicabilityRequiresShortcutsCLI {
    // On macOS 12+ /usr/bin/shortcuts ships with the OS. Gate on the binary so
    // the action disappears cleanly if Apple ever removes it.
    BOOL applicable = [RunShortcutAction isActionApplicableToSystem];
    BOOL cliPresent = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/usr/bin/shortcuts"];
    XCTAssertEqual(applicable, cliPresent);
}

- (void)testEmptyShortcutNameFailsWithoutInvokingCLI {
    RunShortcutAction *action = (RunShortcutAction *)[Action actionFromDictionary:@{
        @"type": @"RunShortcut",
        @"parameter": @"",
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error rangeOfString:@"Shortcut" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (void)testWhitespaceOnlyShortcutNameFails {
    RunShortcutAction *action = [[RunShortcutAction alloc] initWithDictionary:@{
        @"type": @"RunShortcut",
        @"parameter": @"   ",
        @"context": @"",
        @"when": @"Arrival",
        @"delay": @0,
        @"enabled": @YES
    }];
    NSString *error = nil;
    XCTAssertFalse([action execute:&error]);
    XCTAssertNotNil(error);
}

- (void)testFriendlyMetadata {
    XCTAssertGreaterThan([RunShortcutAction friendlyName].length, 0u);
    XCTAssertGreaterThan([RunShortcutAction helpText].length, 0u);
    XCTAssertGreaterThan([RunShortcutAction creationHelpText].length, 0u);
    XCTAssertGreaterThan([RunShortcutAction menuCategory].length, 0u);
}

- (void)testHelpTextNamesGalleryPresets {
    NSString *help = [RunShortcutAction helpText];
    XCTAssertTrue([help rangeOfString:@"Shortcuts recipe gallery" options:0].location != NSNotFound,
                  @"Prefs help for Run Shortcut must point at the gallery (#127)");
    for (NSString *name in @[
        @"Enable Work Focus",
        @"Connect Work VPN",
        @"Turn Bluetooth On",
        @"Turn Stage Manager On",
    ]) {
        XCTAssertTrue([help containsString:name],
                      @"Run Shortcut prefs help must suggest gallery name %@ (#127)", name);
    }
}

@end
