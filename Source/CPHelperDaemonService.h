//
//  CPHelperDaemonService.h
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

NS_ASSUME_NONNULL_BEGIN

/// Wraps SMAppService daemon registration for the in-bundle privileged helper.
/// Privileged commands use daemon status and never call SMJobBless. Registration
/// stays on the prefs checkbox; preparePrivilegedCommand: does not auto-register.
@interface CPHelperDaemonService : NSObject

+ (instancetype)sharedService;

/// Plist filename passed to +[SMAppService daemonServiceWithPlistName:].
+ (NSString *)launchDaemonPlistName;

/// YES when the LaunchDaemon is enabled (not merely awaiting approval).
- (BOOL)isEnabled;

/// Privileged commands may connect to the helper Mach service only when status is Enabled.
+ (BOOL)privilegedCommandMayConnectForStatus:(SMAppServiceStatus)status;

/// Opens Login Items approval when the daemon is not Enabled. Never calls SMJobBless
/// and does not auto-register. Returns YES only when status is already Enabled.
- (BOOL)preparePrivilegedCommand;

/// Blessed SMJobBless copies that must be removed so they cannot share the Mach name.
+ (NSArray<NSString *> *)legacyBlessedInstallPaths;

/// `launchctl bootout` target for the legacy system job (`system/<label>`).
+ (NSString *)legacyBlessedLaunchdBootoutTarget;

/// YES when the prefs checkbox should appear checked (Enabled or RequiresApproval).
- (BOOL)checkboxOn;

/// Maps SMAppService status to checkbox on/off.
/// Enabled and RequiresApproval → on; NotRegistered / NotFound → off.
+ (BOOL)checkboxStateForStatus:(SMAppServiceStatus)status;

/// Current SMAppService status for the embedded helper LaunchDaemon.
- (SMAppServiceStatus)status;

/// Register or unregister the helper daemon. On RequiresApproval, opens Login Items.
/// Returns YES if the resulting checkbox state matches the requested enabled flag
/// (or RequiresApproval after a successful register attempt).
- (BOOL)setEnabled:(BOOL)enabled error:(NSError * _Nullable * _Nullable)error;

/// Opens System Settings → Login Items (macOS 13+).
+ (void)openLoginItemsSettings;

+ (NSString *)allowHelperCheckboxTitle;
+ (NSString *)allowHelperCheckboxToolTip;
+ (NSString *)registrationFailedAlertTitle;
+ (NSString *)registrationFailedAlertMessage;

@end

NS_ASSUME_NONNULL_END
