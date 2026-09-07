//
//  CPContextAppIntentTests.m
//  ControlPlaneTests
//
//  Switch Context token resolution + intent registration smoke (#126).
//

#import <XCTest/XCTest.h>
#import "CPContextAppIntentTokens.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPContextAppIntentTests : XCTestCase
@end

@implementation CPContextAppIntentTests

- (Context *)contextNamed:(NSString *)name parent:(Context *)parent {
    Context *context = [[Context alloc] init];
    context.name = name;
    if (parent != nil) {
        context.parentUUID = parent.uuid;
    }
    return context;
}

- (NSString *)sourceRoot {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    return root;
}

- (void)testUniqueNamesMatchTheForceContextMenuTitles {
    Context *home = [self contextNamed:@"Home" parent:nil];
    Context *work = [self contextNamed:@"Work" parent:nil];

    NSArray *ordered = @[ home, work ];
    NSArray<NSString *> *tokens = [CPContextAppIntentTokens tokensForContextsInMenuOrder:ordered];
    NSArray<NSString *> *expected = @[ @"Home", @"Work" ];
    XCTAssertEqualObjects(tokens, expected);
    XCTAssertEqual([CPContextAppIntentTokens contextMatchingToken:@"Work" inMenuOrder:ordered], work);
}

- (void)testDuplicateNamesUseTheParentPath {
    Context *home = [self contextNamed:@"Home" parent:nil];
    Context *office = [self contextNamed:@"Office" parent:home];
    Context *work = [self contextNamed:@"Work" parent:nil];
    Context *workOffice = [self contextNamed:@"Office" parent:work];

    NSArray *ordered = @[ home, office, work, workOffice ];
    NSArray<NSString *> *tokens = [CPContextAppIntentTokens tokensForContextsInMenuOrder:ordered];
    NSArray<NSString *> *expected = @[ @"Home", @"Home/Office", @"Work", @"Work/Office" ];
    XCTAssertEqualObjects(tokens, expected);

    XCTAssertEqual([CPContextAppIntentTokens contextMatchingToken:@"Home/Office" inMenuOrder:ordered], office);
    XCTAssertEqual([CPContextAppIntentTokens contextMatchingToken:@"Work/Office" inMenuOrder:ordered], workOffice);
    XCTAssertNil([CPContextAppIntentTokens contextMatchingToken:@"Office" inMenuOrder:ordered],
                 @"A duplicated bare name must not pick an arbitrary context");
}

- (void)testUnknownTokenDoesNotMatch {
    Context *home = [self contextNamed:@"Home" parent:nil];
    NSArray *ordered = @[ home ];
    XCTAssertNil([CPContextAppIntentTokens contextMatchingToken:@"  " inMenuOrder:ordered]);
    XCTAssertNil([CPContextAppIntentTokens contextMatchingToken:@"Missing" inMenuOrder:ordered]);
}

- (void)testSwitchContextIntentIsRegisteredWithoutActivatingTheApp {
    NSString *path = [[self sourceRoot] stringByAppendingPathComponent:@"Source/SwitchContextIntent.swift"];
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([source containsString:@"static var title: LocalizedStringResource = \"Switch Context\""]);
    XCTAssertTrue([source containsString:@"static var openAppWhenRun: Bool = false"]);
    XCTAssertTrue([source containsString:@"forceSwitch(toContextNamed:"]);
    XCTAssertTrue([source containsString:@"ControlPlaneAppShortcuts"]);
}

- (void)testIntentUsesTheStatusMenuForceSwitchPath {
    NSString *path = [[self sourceRoot] stringByAppendingPathComponent:@"Source/CPController.m"];
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);

    NSRange method = [source rangeOfString:@"- (BOOL)forceSwitchToContextNamed:"];
    XCTAssertTrue(method.location != NSNotFound);
    NSString *after = [source substringFromIndex:method.location];
    NSRange nextMark = [after rangeOfString:@"#pragma mark"];
    NSString *body = nextMark.location != NSNotFound ? [after substringToIndex:nextMark.location] : after;
    XCTAssertTrue([body containsString:@"[self forceSwitch:context]"],
                  @"Named switch must call the status-menu forceSwitch: path");
}

- (void)testHelpDocumentsSwitchContextIntent {
    NSString *path = [[self sourceRoot] stringByAppendingPathComponent:@"Resources/ControlPlane Help/pages/tips.html"];
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([html containsString:@"Switch Context"]);
    XCTAssertTrue([html rangeOfString:@"Shortcuts" options:NSCaseInsensitiveSearch].location != NSNotFound);
    XCTAssertTrue([html rangeOfString:@"Spotlight" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (void)testAgentLifecycleAndSandboxAreUnchanged {
    NSString *root = [self sourceRoot];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[root stringByAppendingPathComponent:@"Info.plist"]];
    XCTAssertEqualObjects(info[@"LSUIElement"], @"1");

    NSDictionary *entitlements = [NSDictionary dictionaryWithContentsOfFile:
                                  [root stringByAppendingPathComponent:@"ControlPlane.entitlements"]];
    XCTAssertNil(entitlements[@"com.apple.security.app-sandbox"]);
}

@end
