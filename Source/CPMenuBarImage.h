//
//  CPMenuBarImage.h
//  ControlPlane
//
//  Thin helper so status-item artwork stays template-rendered on transparent
//  Tahoe / Liquid Glass menu bars (#89). Full Asset Catalog work is #32.
//

#import <Cocoa/Cocoa.h>

@interface CPMenuBarImage : NSObject

/// Scales `image` for the menu bar and marks it as a template so AppKit can
/// adapt contrast against light, dark, and translucent menu-bar backgrounds.
+ (NSImage *)configureAsMenuBarTemplate:(NSImage *)image size:(NSSize)size;

@end
