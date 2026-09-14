//
//  GeneralSettingsController.h
//  ControlPlane
//
//  ObjC host that owns the SwiftUI GeneralSettingsView (#203) and exposes its
//  hosted NSViewController for embedding inside the AppKit General prefs
//  pane. Keeps NSHostingController / generic Swift types out of
//  PrefsWindowController; callers only see plain ObjC/AppKit types here.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeneralSettingsController : NSObject

/// - useNotifications / startAtLogin / allowPrivilegedHelper: initial toggle
///   state, read from the existing services/defaults at install time.
/// - Each apply block receives the requested new value and must return the
///   actual resulting value (mirrors the existing PrefsWindowController
///   startAtLogin / allowPrivilegedHelper alert-on-failure flows; login item
///   and helper registration can fail or require approval).
- (instancetype)initWithUseNotifications:(BOOL)useNotifications
                             startAtLogin:(BOOL)startAtLogin
                   allowPrivilegedHelper:(BOOL)allowPrivilegedHelper
                   applyUseNotifications:(BOOL (^)(BOOL enabled))applyUseNotifications
                        applyStartAtLogin:(BOOL (^)(BOOL enabled))applyStartAtLogin
               applyAllowPrivilegedHelper:(BOOL (^)(BOOL enabled))applyAllowPrivilegedHelper;

/// Hosted SwiftUI view; the caller positions/sizes it within the AppKit pane.
@property (nonatomic, readonly) NSView *view;

/// Refresh toggle state, e.g. when the prefs window reopens.
- (void)refreshWithStartAtLogin:(BOOL)startAtLogin allowPrivilegedHelper:(BOOL)allowPrivilegedHelper;

@end

NS_ASSUME_NONNULL_END
