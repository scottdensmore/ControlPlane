//
//  CPMenuBarImage.m
//  ControlPlane
//

#import "CPMenuBarImage.h"

@implementation CPMenuBarImage

+ (NSImage *)menuBarImageNamed:(NSString *)name size:(NSSize)size {
	if (name.length == 0) {
		return nil;
	}
	return [self configureAsMenuBarTemplate:[NSImage imageNamed:name] size:size];
}

+ (NSImage *)configureAsMenuBarTemplate:(NSImage *)image size:(NSSize)size {
	if (image == nil) {
		return nil;
	}

	NSImage *configured = [image copy];
	configured.size = size;
	configured.template = YES;
	return configured;
}

@end
