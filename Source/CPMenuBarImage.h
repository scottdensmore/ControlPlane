//
//  CPMenuBarImage.h
//  ControlPlane
//
//  Status-item artwork helpers: Asset Catalog names + template rendering for
//  light/dark / translucent menu bars (#32; template path from #89).
//

#import <Cocoa/Cocoa.h>

@interface CPMenuBarImage : NSObject

/// Loads `name` from the Asset Catalog (or legacy bundle image) and prepares it
/// for the status item. Copies before mutating so shared `imageNamed:` instances
/// (e.g. About panel) are not flipped to template unexpectedly.
+ (NSImage *)menuBarImageNamed:(NSString *)name size:(NSSize)size;

/// Scales `image` for the menu bar and marks a copy as a template so AppKit can
/// adapt contrast against light, dark, and translucent menu-bar backgrounds.
+ (NSImage *)configureAsMenuBarTemplate:(NSImage *)image size:(NSSize)size;

@end
