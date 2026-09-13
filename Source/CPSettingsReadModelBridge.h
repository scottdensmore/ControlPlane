//
//  CPSettingsReadModelBridge.h
//  ControlPlane
//
//  Live lists (Context, Evidence, Action type) for the upcoming SwiftUI
//  Settings panes. Calls through the same running CPController / registries
//  the AppKit prefs UI already uses; never opens or owns a window. Runs on
//  the main thread (hopping if needed), same pattern as
//  CPContextAppIntentBridge.
//

#import <Foundation/Foundation.h>

@interface CPSettingsReadModelBridge : NSObject

/// Force Context menu rows (@"id", @"name"), in menu order.
/// Empty array if ControlPlane is not running / not ready yet.
+ (NSArray<NSDictionary *> *)orderedContextRows;

/// Evidence source rows (@"id", @"name", @"enabled").
/// Empty array if ControlPlane is not running / not ready yet.
+ (NSArray<NSDictionary *> *)evidenceRows;

/// Registered action type rows (@"id", @"name") from the same class registry
/// PrefsWindowController's Actions tab uses. Does not execute any action.
+ (NSArray<NSDictionary *> *)actionTypeRows;

@end
