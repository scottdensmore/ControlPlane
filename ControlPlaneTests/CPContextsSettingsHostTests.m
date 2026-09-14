#import <XCTest/XCTest.h>

@interface CPContextsSettingsHostTests : XCTestCase
@end

@implementation CPContextsSettingsHostTests

- (NSString *)sourceTextAtRelativePath:(NSString *)relativePath {
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *path = [root stringByAppendingPathComponent:relativePath];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"%@", error);
    XCTAssertTrue(text.length > 0, @"missing %@", relativePath);
    return text;
}

- (void)testContextsSwiftUIPreservesAccessibilityIds {
    NSString *swift = [self sourceTextAtRelativePath:@"Source/ContextsSettingsView.swift"];
    XCTAssertTrue([swift containsString:@"prefs.contexts.list"]);
    XCTAssertTrue([swift containsString:@"prefs.contexts.add"]);
    XCTAssertTrue([swift containsString:@"prefs.contexts.remove"]);
    XCTAssertTrue([swift containsString:@"prefs.contexts.edit"]);
    // Pane root must NOT be set on the SwiftUI host (General lesson).
    XCTAssertFalse([swift containsString:@"prefs.tab.contexts"],
                   @"prefs.tab.contexts belongs on contextsPrefsView only");
}

- (void)testContextsHostInstallMethodExists {
    NSString *prefs = [self sourceTextAtRelativePath:@"Source/PrefsWindowController.m"];
    XCTAssertTrue([prefs containsString:@"installContextsSettingsHostedView"]);
    NSString *header = [self sourceTextAtRelativePath:@"Source/ContextsSettingsController.h"];
    XCTAssertTrue([header containsString:@"@interface ContextsSettingsController"]);
}

- (void)testContextsDataSourceExposesSelectionAndEditForHost {
    NSString *header = [self sourceTextAtRelativePath:@"Source/ContextsDataSource.h"];
    XCTAssertTrue([header containsString:@"editSelectedContext:"]);
    XCTAssertTrue([header containsString:@"selectContextWithUUID:"]);
}

- (void)testContextsSheetAccessibilityIdsDocumentedInSource {
    NSString *ds = [self sourceTextAtRelativePath:@"Source/ContextsDataSource.m"];
    XCTAssertTrue([ds containsString:@"prefs.contexts.sheet.name"]);
    XCTAssertTrue([ds containsString:@"prefs.contexts.sheet.confirm"]);
}

@end
