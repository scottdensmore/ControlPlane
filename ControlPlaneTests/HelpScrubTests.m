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
    XCTAssertTrue([html rangeOfString:@"distributed notification" options:NSCaseInsensitiveSearch].location != NSNotFound,
                  @"Evidence Sources Help must warn that Screen Lock / Remote Desktop use distributed notifications (#130)");
    XCTAssertTrue([html rangeOfString:@"com.apple.screenIsLocked" options:0].location != NSNotFound,
                  @"Help should name Screen Lock notification (#130)");
    XCTAssertTrue([html rangeOfString:@"com.apple.remotedesktop.viewerNames" options:0].location != NSNotFound,
                  @"Help should name Remote Desktop notification (#130)");
}

// #127: curated Shortcuts recipes so users can replace gated Focus/VPN/BT/Stage Manager actions.

- (void)testHelpDocumentsShortcutsRecipeGallery {
    NSString *path = [self.helpRoot stringByAppendingPathComponent:@"pages/tips.html"];
    NSError *error = nil;
    NSString *tips = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(tips);

    NSArray<NSString *> *required = @[
        @"Shortcuts recipe gallery",
        @"Set Focus",
        @"Set VPN",
        @"Set Bluetooth",
        @"Set Stage Manager",
        @"Enable Work Focus",
        @"Connect Work VPN",
        @"Turn Bluetooth On",
        @"Turn Stage Manager On",
        @"Run Shortcut",
        @"macOS 26",
        @"Switch Context",
    ];
    for (NSString *needle in required) {
        XCTAssertTrue([tips rangeOfString:needle options:0].location != NSNotFound,
                      @"Tips Help must document Shortcuts recipe (%@) (#127)", needle);
    }

    NSArray<NSString *> *banned = @[
        @"IOBluetoothPreference",
        @"NEVPNManager",
        @"shortcuts run",
    ];
    for (NSString *needle in banned) {
        XCTAssertFalse([tips containsString:needle],
                       @"Tips must not recommend private or shell automation (%@) (#127)", needle);
    }

    NSString *actionsPath = [self.helpRoot stringByAppendingPathComponent:@"pages/actions.html"];
    NSString *actions = [NSString stringWithContentsOfFile:actionsPath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([actions containsString:@"tips.html"],
                  @"Actions Help must link to the Shortcuts recipe gallery (#127)");
    XCTAssertTrue([actions rangeOfString:@"Shortcuts recipe gallery" options:0].location != NSNotFound,
                  @"Actions Help must name the Shortcuts recipe gallery (#127)");
    XCTAssertFalse([actions containsString:@"shortcuts run \""],
                   @"Actions Help must not tell users to shell out to shortcuts (#127)");
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

// #170: General Help documents Allow privileged helper; Time Machine no longer says click Install.

- (void)testHelpDocumentsAllowPrivilegedHelperApproval {
    NSError *error = nil;
    NSString *configPath = [self.helpRoot stringByAppendingPathComponent:@"pages/config.html"];
    NSString *config = [NSString stringWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(config);

    NSRange startAtLogin = [config rangeOfString:@"Start ControlPlane at Login"];
    XCTAssertTrue(startAtLogin.location != NSNotFound, @"General Help must still document Start at Login");
    NSString *afterLogin = [config substringFromIndex:startAtLogin.location];
    NSRange helperHeading = [afterLogin rangeOfString:@"Allow privileged helper"];
    XCTAssertTrue(helperHeading.location != NSNotFound,
                  @"General Help must document Allow privileged helper next to Start at Login (#170)");

    NSRange nextH2 = [afterLogin rangeOfString:@"<h2>" options:0 range:NSMakeRange(1, afterLogin.length - 1)];
    NSString *followingSection = nextH2.location != NSNotFound ? [afterLogin substringFromIndex:nextH2.location] : afterLogin;
    NSString *followingHeading = [followingSection substringToIndex:MIN((NSUInteger)80, followingSection.length)];
    XCTAssertTrue([followingHeading rangeOfString:@"Allow privileged helper"].location != NSNotFound,
                  @"The section after Start at Login must be Allow privileged helper (#170)");

    XCTAssertTrue([config rangeOfString:@"Login Item"].location != NSNotFound,
                  @"General Help must say the helper is registered as a Login Item (#170)");
    XCTAssertTrue([config rangeOfString:@"Login Items & Extensions"].location != NSNotFound
                  || [config rangeOfString:@"Login Items &amp; Extensions"].location != NSNotFound,
                  @"General Help must point at System Settings → General → Login Items & Extensions (#170)");
    XCTAssertTrue([config rangeOfString:@"does not turn itself on at launch" options:NSCaseInsensitiveSearch].location != NSNotFound,
                  @"General Help must say the helper does not turn itself on at launch (#170)");
    NSRange helperNextH2 = [followingSection rangeOfString:@"<h2>" options:0 range:NSMakeRange(1, followingSection.length - 1)];
    NSString *helperSection = helperNextH2.location != NSNotFound
        ? [followingSection substringToIndex:helperNextH2.location]
        : followingSection;
    XCTAssertTrue([helperSection rangeOfString:@"General settings"].location != NSNotFound,
                  @"Allow privileged helper Help must say General settings (#170)");
    XCTAssertFalse([helperSection rangeOfString:@"General preferences"].location != NSNotFound,
                   @"Allow privileged helper Help must not say General preferences (#170)");

    NSString *actionsPath = [self.helpRoot stringByAppendingPathComponent:@"pages/actions.html"];
    NSString *actions = [NSString stringWithContentsOfFile:actionsPath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    NSRange tmHeading = [actions rangeOfString:@"Toggle Time Machine"];
    XCTAssertTrue(tmHeading.location != NSNotFound);
    NSString *afterTM = [actions substringFromIndex:tmHeading.location];
    NSRange tmNextH2 = [afterTM rangeOfString:@"<h2>" options:0 range:NSMakeRange(1, afterTM.length - 1)];
    NSString *tmSection = tmNextH2.location != NSNotFound ? [afterTM substringToIndex:tmNextH2.location] : afterTM;
    XCTAssertFalse([tmSection rangeOfString:@"click install" options:NSCaseInsensitiveSearch].location != NSNotFound,
                   @"Toggle Time Machine Help must not tell the user to click Install (#170)");
    XCTAssertFalse([tmSection containsString:@"install the helper application"],
                   @"Toggle Time Machine Help must not describe a helper install dialog (#170)");
    XCTAssertTrue([tmSection rangeOfString:@"Allow privileged helper"].location != NSNotFound,
                  @"Toggle Time Machine Help must point at the General checkbox (#170)");
    XCTAssertTrue([tmSection rangeOfString:@"Login Items"].location != NSNotFound,
                  @"Toggle Time Machine Help must point at Login Items approval (#170)");
    XCTAssertTrue([tmSection rangeOfString:@"General settings"].location != NSNotFound,
                  @"Toggle Time Machine Help must say General settings (#170)");
    XCTAssertFalse([tmSection rangeOfString:@"General preferences"].location != NSNotFound,
                   @"Toggle Time Machine Help must not say General preferences (#170)");

    NSString *html = [self concatenatedHelpHTML];
    NSArray<NSString *> *cutoverClaims = @[
        @"left SMJobBless",
        @"no longer uses SMJobBless",
        @"no longer use SMJobBless",
        @"cut over off",
        @"have already left SMJobBless",
    ];
    for (NSString *needle in cutoverClaims) {
        XCTAssertFalse([html rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound,
                       @"Help must not claim privileged commands have left SMJobBless (%@) (#170)", needle);
    }
}

// #176: Toggle Remote Login Help points at Allow privileged helper, not “when first needed.”

- (void)testHelpRemoteLoginPointsAtPrivilegedHelperApproval {
    NSError *error = nil;
    NSString *actionsPath = [self.helpRoot stringByAppendingPathComponent:@"pages/actions.html"];
    NSString *actions = [NSString stringWithContentsOfFile:actionsPath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(actions);

    NSRange rlHeading = [actions rangeOfString:@"Toggle Remote Login"];
    XCTAssertTrue(rlHeading.location != NSNotFound, @"Actions Help must document Toggle Remote Login");
    NSString *afterRL = [actions substringFromIndex:rlHeading.location];
    NSRange rlNextH2 = [afterRL rangeOfString:@"<h2>" options:0 range:NSMakeRange(1, afterRL.length - 1)];
    NSString *rlSection = rlNextH2.location != NSNotFound ? [afterRL substringToIndex:rlNextH2.location] : afterRL;

    XCTAssertTrue([rlSection rangeOfString:@"Allow privileged helper"].location != NSNotFound,
                  @"Toggle Remote Login Help must point at Allow privileged helper (#176)");
    XCTAssertTrue([rlSection rangeOfString:@"Login Items"].location != NSNotFound,
                  @"Toggle Remote Login Help must point at Login Items (#176)");
    XCTAssertTrue([rlSection rangeOfString:@"General settings"].location != NSNotFound,
                  @"Toggle Remote Login Help must say General settings (#176)");
    XCTAssertFalse([rlSection rangeOfString:@"General preferences"].location != NSNotFound,
                   @"Toggle Remote Login Help must not say General preferences (#176)");
    XCTAssertFalse([rlSection rangeOfString:@"when first needed" options:NSCaseInsensitiveSearch].location != NSNotFound,
                   @"Toggle Remote Login Help must not say the helper is used when first needed (#176)");
}

@end
