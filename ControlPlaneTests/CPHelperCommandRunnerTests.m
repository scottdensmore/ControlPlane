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

- (void)testFirewallUsesSocketFilterFWNotALFDefaults
{
    XCTAssertEqualObjects(kCPHelperPathSocketFilterFW,
                          @"/usr/libexec/ApplicationFirewall/socketfilterfw");
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForFirewallEnable],
                          (@[ @"--setglobalstate", @"on" ]));
    XCTAssertEqualObjects([CPHelperCommandRunner argumentsForFirewallDisable],
                          (@[ @"--setglobalstate", @"off" ]));
    XCTAssertTrue([[NSFileManager defaultManager] isExecutableFileAtPath:kCPHelperPathSocketFilterFW],
                  @"socketfilterfw must exist on Tahoe; do not revive defaults write com.apple.alf");
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
