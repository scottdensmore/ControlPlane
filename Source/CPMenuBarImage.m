//
//  CPMenuBarImage.m
//  ControlPlane
//

#import "CPMenuBarImage.h"

@implementation CPMenuBarImage

+ (NSImage *)configureAsMenuBarTemplate:(NSImage *)image size:(NSSize)size {
	if (image == nil) {
		return nil;
	}

	[image setSize:size];
	[image setTemplate:YES];
	return image;
}

@end
