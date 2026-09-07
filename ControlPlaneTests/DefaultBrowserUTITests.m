//
//  DefaultBrowserUTITests.m
//  ControlPlaneTests
//
//  Characterizes that ControlPlane does not claim over-broad UTI types (e.g. public.text)
//  that would make it a default handler for generic text files under macOS Sequoia.
//  Also locks DefaultBrowserAction to UniformTypeIdentifiers (no deprecated kUTType*).
//

#import <XCTest/XCTest.h>
#import <CoreServices/CoreServices.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface DefaultBrowserUTITests : XCTestCase
@end

@implementation DefaultBrowserUTITests

- (NSString *)srcRoot {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    return root;
}

- (NSString *)defaultBrowserActionSource {
    NSString *path = [self.srcRoot stringByAppendingPathComponent:@"Source/DefaultBrowserAction.m"];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    XCTAssertNil(error, @"Failed reading %@: %@", path, error);
    XCTAssertNotNil(text);
    return text ?: @"";
}

- (NSDictionary *)infoDictionary {
    // When running tests, mainBundle is the test bundle, not the app bundle.
    // We need to find the app bundle relative to the test bundle.
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *appPath = [[testBundle.bundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ControlPlane.app"];
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    
    if (!appBundle) {
        // Fallback to main bundle if we can't find the app bundle
        appBundle = [NSBundle mainBundle];
    }
    
    XCTAssertNotNil(appBundle, @"Could not find ControlPlane.app bundle");
    return appBundle.infoDictionary;
}

- (void)testDefaultBrowserActionUsesUTTypeAPIsNotDeprecatedKUTType {
    NSString *source = [self defaultBrowserActionSource];

    XCTAssertTrue([source containsString:@"UniformTypeIdentifiers"],
                  @"DefaultBrowserAction.m must import UniformTypeIdentifiers");
    XCTAssertTrue([source containsString:@"UTTypeHTML"],
                  @"DefaultBrowserAction.m must use UTTypeHTML");
    XCTAssertTrue([source containsString:@"UTTypeURL"],
                  @"DefaultBrowserAction.m must use UTTypeURL");

    // No deprecated MobileCoreServices / LaunchServices UTI constants in this path
    XCTAssertFalse([source containsString:@"kUTType"],
                   @"DefaultBrowserAction.m must not use deprecated kUTType* constants");
}

- (NSUInteger)countOfRegex:(NSString *)pattern inString:(NSString *)source {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                        options:0
                                                                          error:NULL];
    return [re numberOfMatchesInString:source options:0 range:NSMakeRange(0, source.length)];
}

- (void)testDefaultBrowserActionKeepsNarrowBrowserContentTypes {
    // Keep #43 policy: register HTML + URL only — never generic public.text.
    NSString *source = [self defaultBrowserActionSource];
    XCTAssertGreaterThan([self countOfRegex:@"\\bUTTypeHTML\\b" inString:source], 0u,
                         @"Must register HTML content type for browser role");
    XCTAssertGreaterThan([self countOfRegex:@"\\bUTTypeURL\\b" inString:source], 0u,
                         @"Must register URL content type for browser role");
    XCTAssertEqual([self countOfRegex:@"\\bpublic\\.text\\b" inString:source], 0u,
                   @"Must not register generic public.text");
    // Word-boundary avoids false hits on historical kUTTypeText / kUTTypeFileURL comments.
    XCTAssertEqual([self countOfRegex:@"\\bUTTypeText\\b" inString:source], 0u,
                   @"Must not register UTTypeText / generic text");
    XCTAssertEqual([self countOfRegex:@"\\bUTTypePlainText\\b" inString:source], 0u,
                   @"Must not register UTTypePlainText");
    XCTAssertEqual([self countOfRegex:@"\\bUTTypeFileURL\\b" inString:source], 0u,
                   @"Must not broaden to file URL claims");
}

- (void)testDefaultBrowserDoesNotRegisterHandlerFromInit {
    NSString *source = [self defaultBrowserActionSource];
    XCTAssertFalse([source containsString:@"setControlPlaneAsURLHandler"],
                   @"Do not register the system handler while constructing the action (#134)");
    XCTAssertTrue([source containsString:@"registerControlPlaneAsURLHandler"],
                  @"Handler registration belongs on execute");
    NSRange execute = [source rangeOfString:@"- (BOOL) execute"];
    XCTAssertTrue(execute.location != NSNotFound);
    NSString *beforeExecute = [source substringToIndex:execute.location];
    XCTAssertFalse([beforeExecute containsString:@"LSSetDefaultHandlerForURLScheme"],
                   @"init paths must not call LSSetDefaultHandler (#134)");
}

- (void)testInfoPlistDoesNotClaimTextUTI {
    // Verify Info.plist document types do not claim public.text
    NSArray *docTypes = self.infoDictionary[@"CFBundleDocumentTypes"];
    
    for (NSDictionary *docType in docTypes) {
        NSArray *contentTypes = docType[@"LSItemContentTypes"];
        if (contentTypes) {
            for (NSString *uti in contentTypes) {
                // Should not claim public.text or public.plain-text
                XCTAssertFalse([uti isEqualToString:@"public.text"],
                              @"Info.plist should not claim public.text UTI");
                XCTAssertFalse([uti isEqualToString:@"public.plain-text"],
                              @"Info.plist should not claim public.plain-text UTI");
            }
        }
    }
}

- (void)testInfoPlistDeclaresHTTPAndHTTPSURLSchemes {
    // Verify Info.plist declares http and https URL schemes for browser functionality
    NSArray *urlTypes = self.infoDictionary[@"CFBundleURLTypes"];
    XCTAssertNotNil(urlTypes, @"CFBundleURLTypes should be present");
    
    BOOL foundHTTP = NO;
    BOOL foundHTTPS = NO;
    
    for (NSDictionary *urlType in urlTypes) {
        NSArray *schemes = urlType[@"CFBundleURLSchemes"];
        for (NSString *scheme in schemes) {
            if ([scheme isEqualToString:@"http"]) {
                foundHTTP = YES;
            }
            if ([scheme isEqualToString:@"https"]) {
                foundHTTPS = YES;
            }
        }
    }
    
    XCTAssertTrue(foundHTTP, @"Info.plist should declare http URL scheme");
    XCTAssertTrue(foundHTTPS, @"Info.plist should declare https URL scheme");
}

- (void)testInfoPlistDocumentTypesAreBrowserSpecific {
    // Verify document types are limited to browser-related types (HTML, not generic text)
    NSArray *docTypes = self.infoDictionary[@"CFBundleDocumentTypes"];
    
    for (NSDictionary *docType in docTypes) {
        NSArray *extensions = docType[@"CFBundleTypeExtensions"];
        
        // Allowed browser-related extensions
        NSSet *allowedExtensions = [NSSet setWithArray:@[@"html", @"htm", @"webloc"]];
        
        for (NSString *ext in extensions) {
            XCTAssertTrue([allowedExtensions containsObject:ext],
                         @"Document type extension '%@' should be browser-specific", ext);
        }
        
        // If MIME types are declared, they should be browser-related
        NSArray *mimeTypes = docType[@"CFBundleTypeMIMETypes"];
        if (mimeTypes) {
            for (NSString *mime in mimeTypes) {
                XCTAssertTrue([mime hasPrefix:@"text/html"] || [mime hasPrefix:@"application/"],
                             @"MIME type '%@' should be browser-specific", mime);
            }
        }
    }
}

@end
