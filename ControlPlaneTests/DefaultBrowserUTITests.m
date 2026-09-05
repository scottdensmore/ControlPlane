//
//  DefaultBrowserUTITests.m
//  ControlPlaneTests
//
//  Characterizes that ControlPlane does not claim over-broad UTI types (e.g. public.text)
//  that would make it a default handler for generic text files under macOS Sequoia.
//

#import <XCTest/XCTest.h>
#import <CoreServices/CoreServices.h>

@interface DefaultBrowserUTITests : XCTestCase
@end

@implementation DefaultBrowserUTITests

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

- (void)testInfoPlistDoesNotClaimTextUTI {
    // Verify Info.plist document types do not claim kUTTypeText (public.text)
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
