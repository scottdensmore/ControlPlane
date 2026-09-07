//
//  HelpScrubTests.m
//  ControlPlaneTests
//
//  Source-level checks that Help no longer recommends Growl or upstream links (#45).
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface HelpScrubTests : XCTestCase
@end

@implementation HelpScrubTests

- (NSString *)helpRoot {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    return [root stringByAppendingPathComponent:@"Resources/ControlPlane Help"];
}

- (NSArray<NSURL *> *)helpHTMLFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator =
        [fm enumeratorAtURL:[NSURL fileURLWithPath:self.helpRoot]
 includingPropertiesForKeys:nil
                    options:NSDirectoryEnumerationSkipsHiddenFiles
               errorHandler:nil];
    NSMutableArray<NSURL *> *files = [NSMutableArray array];
    for (NSURL *url in enumerator) {
        if ([url.pathExtension.lowercaseString isEqualToString:@"html"]) {
            [files addObject:url];
        }
    }
    XCTAssertGreaterThan(files.count, 0u, @"Expected Help HTML under %@", self.helpRoot);
    return files;
}

- (NSString *)concatenatedHelpHTML {
    NSMutableString *combined = [NSMutableString string];
    for (NSURL *url in [self helpHTMLFiles]) {
        NSError *error = nil;
        NSString *text = [NSString stringWithContentsOfURL:url
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
        if (error || text == nil) {
            // Some Help pages are declared us-ascii; fall back so the suite still runs.
            text = [NSString stringWithContentsOfURL:url
                                            encoding:NSISOLatin1StringEncoding
                                               error:&error];
        }
        XCTAssertNil(error, @"Failed reading %@: %@", url.path, error);
        XCTAssertNotNil(text);
        [combined appendString:text ?: @""];
        [combined appendString:@"\n"];
    }
    return combined;
}

- (void)testHelpLinksToThisForkNotUpstream {
    NSString *html = [self concatenatedHelpHTML];
    XCTAssertTrue([html containsString:@"scottdensmore/ControlPlane"],
                  @"Help should link to scottdensmore/ControlPlane");
    XCTAssertFalse([html containsString:@"dustinrue/ControlPlane"],
                   @"Help must not link to dustinrue/ControlPlane");
}

- (void)testHelpDoesNotRecommendGrowl {
    NSString *html = [self concatenatedHelpHTML];
    NSArray<NSString *> *banned = @[
        @"Use Growl",
        @"Enable Growl",
        @"via Growl",
        @"with Growl",
        @"Growl will be used",
    ];
    for (NSString *needle in banned) {
        XCTAssertFalse([html containsString:needle],
                       @"Help must not present Growl as current guidance (%@)", needle);
    }
}

- (void)testHelpScrubsGhostAppSections {
    NSString *html = [self concatenatedHelpHTML];
    NSArray<NSString *> *banned = @[
        @"Play iTunes Playlist",
        @"iChat/Messages Status",
        @"Change Mail IMAP Server",
        @"Change Mail SMTP Server",
        @"Change New Mail Check Interval",
        @"tell application \"Adium\"",
        @"tell application \"iTunes\"",
    ];
    for (NSString *needle in banned) {
        XCTAssertFalse([html containsString:needle],
                       @"Help must not keep ghost guidance (%@)", needle);
    }
}

- (void)testHelpMarksDisplayBrightnessUnsupported {
    NSString *path = [self.helpRoot stringByAppendingPathComponent:@"pages/actions.html"];
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    NSRange heading = [html rangeOfString:@"Display Brightness"];
    XCTAssertTrue(heading.location != NSNotFound);
    NSString *after = [html substringFromIndex:heading.location];
    NSRange nextH2 = [after rangeOfString:@"<h2>" options:0 range:NSMakeRange(1, after.length - 1)];
    NSString *section = nextH2.location != NSNotFound ? [after substringToIndex:nextH2.location] : after;
    XCTAssertTrue([section rangeOfString:@"Unsupported" options:NSCaseInsensitiveSearch].location != NSNotFound
		  || [section rangeOfString:@"unavailable" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (void)testHelpDocumentsFocusAndPowerExtensions {
    NSString *html = [self concatenatedHelpHTML];
    XCTAssertTrue([html rangeOfString:@"Focus" options:NSCaseInsensitiveSearch].location != NSNotFound);
    XCTAssertTrue([html rangeOfString:@"Low Power Mode" options:NSCaseInsensitiveSearch].location != NSNotFound
		  || [html rangeOfString:@"battery charge" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (void)testHelpDocumentsWiFiNeedsLocation {
    NSString *path = [self.helpRoot stringByAppendingPathComponent:@"pages/evidencesources.html"];
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(html);
    XCTAssertTrue([html rangeOfString:@"Location Services" options:NSCaseInsensitiveSearch].location != NSNotFound,
                  @"Evidence Sources Help must explain Wi‑Fi needs Location (#84)");
    XCTAssertTrue([html rangeOfString:@"SSID" options:NSCaseInsensitiveSearch].location != NSNotFound);
}

// #137: Evidence inventory must match EvidenceSourceSetController registry.

- (void)testHelpDocumentsEvidenceRegistryInventory {
    NSString *path = [self.helpRoot stringByAppendingPathComponent:@"pages/evidencesources.html"];
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(html);

    NSArray<NSString *> *required = @[
        @"Active Application",
        @"Active Context",
        @"Attached Power Adapter",
        @"AudioOutput",
        @"Bluetooth",
        @"Bonjour",
        @"CoreLocation",
        @"DNS",
        @"Focus",
        @"FireWire",
        @"Host Availability",
        @"IP",
        @"IPv6",
        @"Laptop Lid",
        @"Light",
        @"Monitor",
        @"Mounted Volume",
        @"NetworkLink",
        @"Power",
        @"Remote Desktop",
        @"RunningApplication",
        @"Screen Lock",
        @"ShellScript",
        @"Sleep/Wake",
        @"TimeOfDay",
        @"USB",
        @"WiFi",
        @"Low Power Mode",
    ];
    for (NSString *needle in required) {
        XCTAssertTrue([html rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound,
                      @"Evidence Sources Help must document registry entry (%@) (#137)", needle);
    }
    XCTAssertFalse([html containsString:@"IPV4 only"],
                   @"IP evidence Help must not claim IPv4-only; IPAddrEvidenceSource supports IPv6 (#137)");
    XCTAssertTrue([html rangeOfString:@"AppleLMUController"].location != NSNotFound,
                  @"Light Help must name AppleLMUController (#122)");
    XCTAssertTrue([html rangeOfString:@"Apple silicon" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                  [html rangeOfString:@"modern Mac" options:NSCaseInsensitiveSearch].location != NSNotFound,
                  @"Light Help must note unavailability on modern Macs / Apple silicon (#122)");
}

// #137: Unavailable actions list must match isActionApplicableToSystem gates.

- (void)testHelpDocumentsUnavailableActionsMatchingGates {
    NSString *path = [self.helpRoot stringByAppendingPathComponent:@"pages/actions.html"];
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(html);

    NSRange heading = [html rangeOfString:@"Unavailable on modern macOS" options:NSCaseInsensitiveSearch];
    XCTAssertTrue(heading.location != NSNotFound, @"actions.html must have an unavailable section (#137)");
    NSString *section = [html substringFromIndex:heading.location];

    NSArray<NSString *> *gated = @[
        @"Toggle FTP",
        @"Toggle TFTP",
        @"Toggle Web Sharing",
        @"Toggle Internet Sharing",
        @"Toggle Bluetooth",
        @"Lock Keychain",
        @"Toggle Natural Scrolling",
        @"Screen Saver Password",
        @"Toggle Notification Center Alerts",
        @"Network Location",
        @"VPN",
        @"Toggle Firewall",
        @"Firewall Rule",
        @"Toggle Printer Sharing",
        @"Time Machine Destination",
        @"Display Brightness",
        @"Screen Saver Time",
    ];
    for (NSString *needle in gated) {
        XCTAssertTrue([section rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound,
                      @"Unavailable list must include gated action (%@) (#137)", needle);
    }
}

@end
