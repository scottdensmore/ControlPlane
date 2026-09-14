//
//  ContextsSettingsController.h
//  ControlPlane
//
//  ObjC host that owns the SwiftUI ContextsSettingsView (#229) and exposes
//  its hosted NSViewController for embedding inside the AppKit Contexts
//  prefs pane. Keeps NSHostingController / generic Swift types out of
//  PrefsWindowController; callers only see plain ObjC/AppKit types here.
//  All context mutation (add/remove/edit/select) is forwarded to the
//  existing ContextsDataSource -- this controller never reimplements
//  persistence, it only bridges the SwiftUI list to it.
//

#import <Cocoa/Cocoa.h>

@class ContextsDataSource;

NS_ASSUME_NONNULL_BEGIN

@interface ContextsSettingsController : NSObject

- (instancetype)initWithDataSource:(ContextsDataSource *)dataSource;

/// Hosted SwiftUI view; the caller positions/sizes it within the AppKit pane.
@property (nonatomic, readonly) NSView *view;

/// Rebuilds the displayed rows from `-[ContextsDataSource orderedTraversal]`,
/// e.g. when the prefs window reopens or contexts change out-of-band.
- (void)reloadRows;

@end

NS_ASSUME_NONNULL_END
