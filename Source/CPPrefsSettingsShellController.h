//
//  CPPrefsSettingsShellController.h
//  ControlPlane
//
//  Settings-style preferences shell (issue #100).
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Preference-style `NSTabViewController` that hosts existing prefs `NSView`s.
/// Uses `NSTabViewControllerTabStyleToolbar` so AppKit owns the Settings-like toolbar.
@interface CPPrefsSettingsShellController : NSTabViewController

/// Invoked after the selected pane changes (user click or programmatic select
/// that was not suppressed). Argument is the prefs group id (e.g. @"General").
@property (nonatomic, copy, nullable) void (^paneSelectionHandler)(NSString *paneName);

/// Build toolbar tabs from PrefsWindowController pane dictionaries.
/// Required keys per entry: name, display_name, icon, view.
- (void)configureWithPaneGroups:(NSArray<NSDictionary *> *)groups;

/// Select a pane by group id without notifying `paneSelectionHandler`.
- (void)selectPaneNamed:(NSString *)name;

/// Currently selected group id, or nil if none.
@property (nonatomic, readonly, nullable) NSString *selectedPaneName;

/// Ordered group ids matching the configured tabs.
@property (nonatomic, readonly) NSArray<NSString *> *paneNames;

@end

NS_ASSUME_NONNULL_END
