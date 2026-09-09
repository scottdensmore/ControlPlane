//
//  CPHelperDaemonServiceTests.m
//  ControlPlaneTests
//
//  Status mapping and in-bundle LaunchDaemon plist for SMAppService (#165).
//  Does not register or unregister a live daemon (unsigned CI cannot bless).
//

#import <XCTest/XCTest.h>
#import <ServiceManagement/ServiceManagement.h>
#import "CPHelperDaemonService.h"

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

static NSString * const CPHelperDaemonLaunchDaemonRelativePath = @"Resources/LaunchDaemons/com.scottdensmore.CPHelperTool.plist";
static NSString * const CPHelperDaemonBundleProgram = @"Contents/Library/LaunchServices/com.scottdensmore.CPHelperTool";

@interface CPHelperDaemonServiceTests : XCTestCase
@end

@implementation CPHelperDaemonServiceTests

- (void)testCheckboxOnWhenEnabled {
    XCTAssertTrue([CPHelperDaemonService checkboxStateForStatus:SMAppServiceStatusEnabled]);
}

- (void)testCheckboxOnWhenRequiresApproval {
    XCTAssertTrue([CPHelperDaemonService checkboxStateForStatus:SMAppServiceStatusRequiresApproval]);
}

- (void)testCheckboxOffWhenNotRegistered {
    XCTAssertFalse([CPHelperDaemonService checkboxStateForStatus:SMAppServiceStatusNotRegistered]);
}

- (void)testCheckboxOffWhenNotFound {
    XCTAssertFalse([CPHelperDaemonService checkboxStateForStatus:SMAppServiceStatusNotFound]);
}

- (void)testSharedServiceReturnsStatusWithoutRegistering {
    SMAppServiceStatus status = [[CPHelperDaemonService sharedService] status];
    XCTAssertTrue(status == SMAppServiceStatusNotRegistered
                  || status == SMAppServiceStatusEnabled
                  || status == SMAppServiceStatusRequiresApproval
                  || status == SMAppServiceStatusNotFound);
    XCTAssertEqualObjects([CPHelperDaemonService launchDaemonPlistName], @"com.scottdensmore.CPHelperTool.plist");
}

- (void)testLaunchDaemonPlistUsesBundleProgramLabelAndMachService {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");

    NSString *plistPath = [root stringByAppendingPathComponent:CPHelperDaemonLaunchDaemonRelativePath];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    XCTAssertNotNil(plist, @"Expected LaunchDaemon plist at %@", plistPath);

    NSString *machName = @"com.scottdensmore.CPHelperTool";
    NSString *constantsPath = [root stringByAppendingPathComponent:@"Common/CPCommonConstants.h"];
    NSString *constants = [NSString stringWithContentsOfFile:constantsPath encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertTrue([constants containsString:@"kHelperToolMachServiceName"]);
    XCTAssertTrue([constants containsString:machName], @"Helper Mach name must stay %@", machName);

    XCTAssertEqualObjects(plist[@"Label"], machName);
    XCTAssertEqualObjects(plist[@"BundleProgram"], CPHelperDaemonBundleProgram);
    XCTAssertEqualObjects(plist[@"AssociatedBundleIdentifiers"], @"com.scottdensmore.ControlPlane");

    NSDictionary *machServices = plist[@"MachServices"];
    XCTAssertTrue([machServices isKindOfClass:[NSDictionary class]]);
    XCTAssertEqualObjects(machServices[machName], @YES);

    NSString *blessPlistPath = [root stringByAppendingPathComponent:@"CPHelperTool/HelperTool-Launchd.plist"];
    NSDictionary *blessPlist = [NSDictionary dictionaryWithContentsOfFile:blessPlistPath];
    XCTAssertNotNil(blessPlist);
    XCTAssertNil(blessPlist[@"BundleProgram"], @"SMJobBless launchd plist must stay unchanged");

    NSString *projectPath = [root stringByAppendingPathComponent:@"ControlPlane.xcodeproj/project.pbxproj"];
    NSError *error = nil;
    NSString *project = [NSString stringWithContentsOfFile:projectPath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([project containsString:@"Contents/Library/LaunchDaemons"],
                  @"App target must copy the LaunchDaemon plist into the bundle");
    XCTAssertTrue([project containsString:@"com.scottdensmore.CPHelperTool.plist"],
                  @"Copy phase should reference the daemon plist name");
}

- (void)testInstallDisablesAutoresizingBeforeGrowingGeneralPrefs {
    NSString *source = [self sourceTextAtRelativePath:@"Source/PrefsWindowController.m"];
    NSRange method = [source rangeOfString:@"- (void)installAllowPrivilegedHelperCheckbox"];
    XCTAssertNotEqual(method.location, NSNotFound);
    NSString *body = [source substringFromIndex:method.location];
    NSRange frameSet = [body rangeOfString:@"generalPrefsView.frame = viewFrame"];
    XCTAssertNotEqual(frameSet.location, NSNotFound);
    NSString *beforeFrame = [body substringToIndex:frameSet.location];
    XCTAssertTrue([beforeFrame containsString:@"generalPrefsView.autoresizesSubviews = NO"],
                  @"Growing generalPrefsView must not apply flexibleMinY before the explicit row shift");
    XCTAssertTrue([body containsString:@"generalPrefsView.autoresizesSubviews = autoresizesSubviews"],
                  @"Restore the previous autoresizesSubviews value after the insert");
}

- (void)testOpenLoginItemsSettingsKeyExistsInEveryShippingLocale {
    NSArray<NSString *> *locales = @[ @"en", @"da-DK", @"de", @"fr", @"it", @"pt-BR", @"pt-PT" ];
    NSString *key = @"Open Login Items Settings";
    for (NSString *locale in locales) {
        NSDictionary<NSString *, NSString *> *catalog = [self catalogForLocale:locale];
        NSString *value = catalog[key];
        XCTAssertNotNil(value, @"%@ missing key: %@", locale, key);
        if (value != nil && ![locale isEqualToString:@"en"]) {
            XCTAssertNotEqualObjects(value, key, @"%@ still English for: %@", locale, key);
        }
    }

    NSDictionary<NSString *, NSString *> *italian = [self catalogForLocale:@"it"];
    NSArray<NSString *> *helperKeys = @[
        @"Allow privileged helper",
        @"Allow ControlPlane's privileged helper in Login Items & Extensions. Approval is required before the helper can run.",
        @"Could Not Allow Privileged Helper",
        @"Open System Settings → General → Login Items & Extensions and allow ControlPlane's privileged helper.",
    ];
    for (NSString *helperKey in helperKeys) {
        NSString *value = italian[helperKey];
        XCTAssertNotNil(value, @"it missing key: %@", helperKey);
        XCTAssertFalse([[value lowercaseString] containsString:@"helper"],
                       @"Italian copy must not leave English helper: %@", value);
    }
}

- (void)testPrivilegedCommandMayConnectOnlyWhenDaemonEnabled {
    XCTAssertTrue([CPHelperDaemonService privilegedCommandMayConnectForStatus:SMAppServiceStatusEnabled]);
    XCTAssertFalse([CPHelperDaemonService privilegedCommandMayConnectForStatus:SMAppServiceStatusRequiresApproval]);
    XCTAssertFalse([CPHelperDaemonService privilegedCommandMayConnectForStatus:SMAppServiceStatusNotRegistered]);
    XCTAssertFalse([CPHelperDaemonService privilegedCommandMayConnectForStatus:SMAppServiceStatusNotFound]);
}

- (void)testLegacyBlessedInstallPathsNameSystemHelperCopies {
    NSArray<NSString *> *paths = [CPHelperDaemonService legacyBlessedInstallPaths];
    XCTAssertEqualObjects(paths, (@[
        @"/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool",
        @"/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist",
    ]));
    XCTAssertEqualObjects([CPHelperDaemonService legacyBlessedLaunchdBootoutTarget],
                          @"system/com.scottdensmore.CPHelperTool");
}

- (void)testAgentDocsDescribeSMAppServiceDaemonNotSMJobBlessInstall {
    NSArray<NSString *> *paths = @[
        @"README.md",
        @"AGENTS.md",
        @"docs/releasing.md",
    ];
    for (NSString *path in paths) {
        NSString *text = [self sourceTextAtRelativePath:path];
        XCTAssertFalse([text containsString:@"blessed via SMJobBless"],
                       @"%@ must not describe the helper as blessed via SMJobBless", path);
        XCTAssertFalse([text containsString:@"SMJobBless / XPC"],
                       @"%@ must not describe the helper as SMJobBless / XPC", path);
        XCTAssertFalse([text containsString:@"SMJobBless topology"],
                       @"%@ must point signing facts at the SMAppService daemon", path);
        XCTAssertFalse([text containsString:@"Migrating SMJobBless"],
                       @"%@ must not treat SMJobBless → SMAppService as future work", path);
        XCTAssertTrue([text containsString:@"SMAppService"],
                      @"%@ must describe the SMAppService daemon path", path);
    }

    NSString *readme = [self sourceTextAtRelativePath:@"README.md"];
    XCTAssertTrue([readme containsString:@"cannot register the daemon"],
                  @"README must say unsigned builds cannot register the daemon");
    XCTAssertFalse([readme containsString:@"helper bless"],
                   @"README must not describe helper install as bless");

    NSString *agents = [self sourceTextAtRelativePath:@"AGENTS.md"];
    XCTAssertTrue([agents containsString:@"CPXPCService"],
                  @"AGENTS.md must not claim CPXPCService has been collapsed");
    XCTAssertTrue([agents containsString:@"installHelperToolWithReply:"],
                  @"AGENTS.md must note unused SMJobBless remains in CPXPCService");
    XCTAssertTrue([agents containsString:@"not on the command path"],
                  @"AGENTS.md must keep unused SMJobBless off the command path");

    NSString *releasing = [self sourceTextAtRelativePath:@"docs/releasing.md"];
    XCTAssertTrue([releasing containsString:@"cannot register"],
                  @"releasing.md must say unsigned builds cannot register the daemon");
    XCTAssertFalse([releasing containsString:@"bless smoke"],
                   @"releasing.md must point signing facts at the daemon path");
}

- (void)testPrivilegedCommandPathUsesDaemonStatusNotSMJobBless {
    NSString *source = [self sourceTextAtRelativePath:@"Source/Action+XPCHelperTool.m"];
    XCTAssertFalse([source containsString:@"SMJobBless"],
                   @"Privileged command path must not call SMJobBless");
    XCTAssertFalse([source containsString:@"installHelperToolWithReply"],
                   @"Privileged command path must not bless via CPXPCService");
    XCTAssertFalse([source containsString:@"SMJobCopyDictionary"],
                   @"A blessed launchd job must not be treated as the helper being ready");
    XCTAssertTrue([source containsString:@"privilegedCommandMayConnectForStatus"]
                  || [source containsString:@"preparePrivilegedCommand"],
                  @"Command path must gate on SMAppService daemon status");
    XCTAssertTrue([source containsString:@"openLoginItemsSettings"]
                  || [source containsString:@"preparePrivilegedCommand"],
                  @"Not-enabled status must open the existing Login Items approval path");

    NSRange perform = [source rangeOfString:@"- (BOOL)helperToolPerformXPCAction:(NSString *)action withParameter:(id)parameter"];
    XCTAssertNotEqual(perform.location, NSNotFound);
    NSString *body = [source substringFromIndex:perform.location];
    NSRange connect = [body rangeOfString:@"isEqualToString:kCPHelperEnableTMCommand"];
    XCTAssertNotEqual(connect.location, NSNotFound);
    NSString *beforeCommands = [body substringToIndex:connect.location];
    XCTAssertTrue([beforeCommands containsString:@"preparePrivilegedCommand"],
                  @"Mach-service command dispatch must wait until the daemon is Enabled");
}

- (void)testUninstallRemovesLegacyBlessedCopiesAndUnregistersDaemon {
    NSString *script = [self sourceTextAtRelativePath:@"Utilities/Uninstall.sh"];
    XCTAssertTrue([script containsString:@"legacy_blessed_install_paths"],
                  @"Uninstall must use a named legacy path list");
    XCTAssertTrue([script containsString:@"unregister_helper_daemon"],
                  @"Uninstall must unregister the SMAppService daemon, not only delete files");
    for (NSString *path in [CPHelperDaemonService legacyBlessedInstallPaths]) {
        XCTAssertTrue([script containsString:path], @"Uninstall missing %@", path);
    }
    XCTAssertTrue([script containsString:[CPHelperDaemonService legacyBlessedLaunchdBootoutTarget]],
                  @"Uninstall must boot out the legacy system job");
    XCTAssertTrue([script containsString:@"launchctl bootout"],
                  @"Uninstall must boot out the shared Mach-name job");
    XCTAssertFalse([script containsString:@"launchctl disable"],
                   @"Do not launchctl disable the SMAppService label; disable persists across register");
}

- (void)testOpenLoginItemsSettingsHopsToMainQueueWithoutSync {
    NSString *source = [self sourceTextAtRelativePath:@"Source/CPHelperDaemonService.m"];
    NSRange method = [source rangeOfString:@"+ (void)openLoginItemsSettings"];
    XCTAssertNotEqual(method.location, NSNotFound);
    NSString *body = [source substringFromIndex:method.location];
    NSRange nextMethod = [body rangeOfString:@"\n+ ("];
    if (nextMethod.location != NSNotFound) {
        body = [body substringToIndex:nextMethod.location];
    }
    XCTAssertTrue([body containsString:@"openSystemSettingsLoginItems"],
                  @"Approval UX must still open Login Items");
    XCTAssertTrue([body containsString:@"NSThread isMainThread"] || [body containsString:@"[NSThread isMainThread]"],
                  @"Open Login Items must run on the main thread");
    XCTAssertTrue([body containsString:@"dispatch_async"],
                  @"Off-main callers must hop with dispatch_async, not block the action thread");
    XCTAssertFalse([body containsString:@"dispatch_sync"],
                   @"dispatch_sync onto main can deadlock the action thread");
}

- (void)testAppTargetCopiesHelperBinaryAndLaunchDaemonPlist {
    NSString *project = [self sourceTextAtRelativePath:@"ControlPlane.xcodeproj/project.pbxproj"];
    NSString *appTarget = [self objectBlockInProject:project
                                         startingWith:@"8D1107260486CEB800E47090 /* ControlPlane */"];
    XCTAssertTrue([appTarget containsString:@"productType = \"com.apple.product-type.application\""]);

    NSArray<NSString *> *appPhaseIDs = [self buildPhaseIDsInTargetBlock:appTarget];
    XCTAssertTrue([self project:project
                    phaseIDs:appPhaseIDs
          containsCopyOfName:@"com.scottdensmore.CPHelperTool"
                     dstPath:@"Contents/Library/LaunchServices"],
                  @"ControlPlane app target must copy the helper binary into Contents/Library/LaunchServices");
    XCTAssertTrue([self project:project
                    phaseIDs:appPhaseIDs
          containsCopyOfName:@"com.scottdensmore.CPHelperTool.plist"
                     dstPath:@"Contents/Library/LaunchDaemons"],
                  @"ControlPlane app target must copy the LaunchDaemon plist into Contents/Library/LaunchDaemons");

    NSString *xpcTarget = [self objectBlockInProject:project
                                         startingWith:@"DE762B762D98BA310095F733 /* CPXPCService */"];
    NSArray<NSString *> *xpcPhaseIDs = [self buildPhaseIDsInTargetBlock:xpcTarget];
    XCTAssertTrue([self project:project
                    phaseIDs:xpcPhaseIDs
          containsCopyOfName:@"com.scottdensmore.CPHelperTool"
                     dstPath:@"Contents/Library/LaunchServices"],
                  @"XPC service LaunchServices copy must stay for SMJobBless");
}

- (NSString *)sourceTextAtRelativePath:(NSString *)relativePath {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
    NSString *path = [root stringByAppendingPathComponent:relativePath];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"Failed reading %@", relativePath);
    return text ?: @"";
}

- (NSDictionary<NSString *, NSString *> *)catalogForLocale:(NSString *)locale {
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *path = [root stringByAppendingPathComponent:[NSString stringWithFormat:@"Resources/%@.lproj/Localizable.strings", locale]];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path usedEncoding:NULL error:&error];
    XCTAssertNil(error, @"Failed reading %@", path);
    NSMutableDictionary<NSString *, NSString *> *catalog = [NSMutableDictionary dictionary];
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^\"((?:\\\\.|[^\"\\\\])*)\"\\s*=\\s*\"((?:\\\\.|[^\"\\\\])*)\"\\s*;"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:NULL];
    [re enumerateMatchesInString:text options:0 range:NSMakeRange(0, text.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        catalog[[text substringWithRange:[result rangeAtIndex:1]]] = [text substringWithRange:[result rangeAtIndex:2]];
    }];
    return catalog;
}

- (NSString *)objectBlockInProject:(NSString *)project startingWith:(NSString *)marker {
    NSRange start = [project rangeOfString:marker];
    XCTAssertNotEqual(start.location, NSNotFound, @"Missing %@", marker);
    NSRange tail = NSMakeRange(start.location, project.length - start.location);
    NSRange end = [project rangeOfString:@"\n\t\t};" options:0 range:tail];
    XCTAssertNotEqual(end.location, NSNotFound);
    return [project substringWithRange:NSMakeRange(start.location, NSMaxRange(end) - start.location)];
}

- (NSArray<NSString *> *)buildPhaseIDsInTargetBlock:(NSString *)targetBlock {
    NSRange phases = [targetBlock rangeOfString:@"buildPhases = ("];
    XCTAssertNotEqual(phases.location, NSNotFound);
    NSRange tail = NSMakeRange(NSMaxRange(phases), targetBlock.length - NSMaxRange(phases));
    NSRange end = [targetBlock rangeOfString:@");" options:0 range:tail];
    NSString *list = [targetBlock substringWithRange:NSMakeRange(NSMaxRange(phases), end.location - NSMaxRange(phases))];
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"([A-F0-9]+) /\\*"
                                                                           options:0
                                                                             error:NULL];
    [re enumerateMatchesInString:list options:0 range:NSMakeRange(0, list.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [ids addObject:[list substringWithRange:[result rangeAtIndex:1]]];
    }];
    return ids;
}

- (BOOL)project:(NSString *)project
       phaseIDs:(NSArray<NSString *> *)phaseIDs
containsCopyOfName:(NSString *)name
        dstPath:(NSString *)dstPath {
    for (NSString *phaseID in phaseIDs) {
        NSString *phase = [self objectBlockInProject:project startingWith:[phaseID stringByAppendingString:@" /*"]];
        if (![phase containsString:[NSString stringWithFormat:@"dstPath = %@;", dstPath]]
            && ![phase containsString:[NSString stringWithFormat:@"dstPath = \"%@\";", dstPath]]) {
            continue;
        }
        if ([phase containsString:[NSString stringWithFormat:@"/* %@ in ", name]]
            || [phase containsString:[NSString stringWithFormat:@"/* %@ */", name]]) {
            return YES;
        }
    }
    return NO;
}

@end
