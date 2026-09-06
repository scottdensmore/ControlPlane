//
//  CPHelperCommandRunnerTests.m
//  ControlPlaneTests
//
//  Characterization / regression for helper argv-array hardening (#86).
//

#import <XCTest/XCTest.h>
#import "CPHelperCommandRunner.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPHelperCommandRunnerTests : XCTestCase
@end

@implementation CPHelperCommandRunnerTests

- (NSString *)helperToolSource
{
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:@"CPHelperTool/CPHelperTool.m"];
    NSError *error = nil;
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNotNil(source, @"Failed reading %@: %@", path, error);
    return source;
}

- (void)testHelperToolSourceDoesNotUseSystemOrSprintfShelling
{
    NSString *source = [self helperToolSource];
    XCTAssertFalse([source containsString:@"system("],
                   @"CPHelperTool.m must not call system(); use argv-array spawn (#86)");
    XCTAssertFalse([source containsString:@"sprintf("],
                   @"CPHelperTool.m must not sprintf command strings for a shell (#86)");
}

- (void)testDisplaySleepMinutesValidation
{
    XCTAssertTrue([CPHelperCommandRunner isValidDisplaySleepMinutes:0]);
    XCTAssertTrue([CPHelperCommandRunner isValidDisplaySleepMinutes:15]);
    XCTAssertTrue([CPHelperCommandRunner isValidDisplaySleepMinutes:1440]);
    XCTAssertFalse([CPHelperCommandRunner isValidDisplaySleepMinutes:-1]);
    XCTAssertFalse([CPHelperCommandRunner isValidDisplaySleepMinutes:1441]);
}

- (void)testDisplaySleepArgvUsesSeparateNumericArgument
{
    NSArray *args = [CPHelperCommandRunner argumentsForDisplaySleepMinutes:30];
    XCTAssertEqualObjects(args, (@[ @"-a", @"displaysleep", @"30" ]));
    // Must not embed minutes in a single shell-ish string.
    for (NSString *arg in args) {
        XCTAssertFalse([arg containsString:@" "]);
        XCTAssertFalse([arg containsString:@";"]);
        XCTAssertFalse([arg containsString:@"|"]);
    }
}

- (void)testHelperRejectsGatedFirewallAndPrinterSharingCommands
{
    // #124: app already gates ToggleFirewall / TogglePrinterSharing; root helper must
    // refuse XPC toggles even if a client asks (same ENOTSUP pattern as Internet Sharing).
    NSString *source = [self helperToolSource];

    XCTAssertTrue([source containsString:@"Firewall cannot be toggled on this version of macOS"],
                  @"enable/disableFirewall must reply with a clear unsupported status (#124)");
    XCTAssertTrue([source containsString:@"Printer Sharing cannot be toggled on this version of macOS"],
                  @"enable/disablePrinterSharing must reply with a clear unsupported status (#124)");

    NSUInteger enotsupCount = 0;
    NSString *needle = @"errorWithCode:ENOTSUP";
    NSRange search = NSMakeRange(0, source.length);
    while (search.location < source.length) {
        NSRange found = [source rangeOfString:needle options:0 range:search];
        if (found.location == NSNotFound) {
            break;
        }
        enotsupCount++;
        search.location = NSMaxRange(found);
        search.length = source.length - search.location;
    }
    // Internet Sharing, AFP, FTP, TFTP, Web Sharing (5×2) + Firewall + Printer Sharing (2×2)
    XCTAssertGreaterThanOrEqual(enotsupCount, 14,
                                 @"Expected gated helpers to use ENOTSUP, including Firewall/Printer Sharing (#124)");

    XCTAssertFalse([source containsString:@"argumentsForFirewallEnable"],
                   @"Helper must not spawn socketfilterfw for EnableFirewall (#124)");
    XCTAssertFalse([source containsString:@"argumentsForFirewallDisable"],
                   @"Helper must not spawn socketfilterfw for DisableFirewall (#124)");
    XCTAssertFalse([source containsString:@"argumentsForPrinterSharingEnable"],
                   @"Helper must not spawn cupsctl for EnablePrinterSharing (#124)");
    XCTAssertFalse([source containsString:@"argumentsForPrinterSharingDisable"],
                   @"Helper must not spawn cupsctl for DisablePrinterSharing (#124)");
    XCTAssertFalse([source containsString:@"kCPHelperPathSocketFilterFW"],
                   @"Gated Firewall path must not remain in CPHelperTool.m (#124)");
    XCTAssertFalse([source containsString:@"kCPHelperPathCupsctl"],
                   @"Gated Printer Sharing path must not remain in CPHelperTool.m (#124)");
}

- (void)testTimeMachineArgvIsFixedLiterals
{
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForTmutilEnable], (@[ @"enable" ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForTmutilDisable], (@[ @"disable" ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForTmutilStartBackup], (@[ @"startbackup" ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForTmutilStopBackup], (@[ @"stopbackup" ]));
}

- (void)testSMBAndRemoteLoginArgvHaveNoUserInterpolation
{
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForSMBEnable],
                          (@[ @"load", @"-F", kCPHelperPathSMBDPlist ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForSMBDisable],
                          (@[ @"unload", @"-F", kCPHelperPathSMBDPlist ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForRemoteLoginEnable],
                          (@[ @"-setremotelogin", @"on" ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForRemoteLoginDisable],
                          (@[ @"-setremotelogin", @"off" ]));
}

- (void)testRunExecutableRejectsMissingBinary
{
    int status = [CPHelperCommandRunner runExecutable:@"/tmp/controlplane-no-such-helper-tool"
                                            arguments:@[ @"--help" ]];
    XCTAssertEqual(status, ENOENT);
}

- (void)testRunExecutableCanInvokeTrue
{
    int status = [CPHelperCommandRunner runExecutable:@"/usr/bin/true" arguments:nil];
    XCTAssertEqual(status, 0);
}

@end
