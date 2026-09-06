//
//	DisplayBrightnessAction.m
//	ControlPlane
//
//	Created by David Jennes on 02/09/11.
//  Modifiedy by Dustin Rue on 19/11/11.
//  inspired by http://dev.sabi.net/trac/dev/browser/trunk/LocationDo/brightness.m
//
//	Copyright 2011. All rights reserved.
//

#import "DisplayBrightnessAction.h"


@implementation DisplayBrightnessAction

+ (BOOL)isActionApplicableToSystem
{
	// #88: IOKit kIODisplayBrightnessKey via IODisplayConnect is unreliable on
	// Tahoe (Apple silicon built-ins and many externals). Working alternatives
	// (DisplayServices / CoreDisplay / CoreBrightness) are private APIs. Prefer
	// a clear gate over private symbols or silent no-op success.
	return NO;
}

- (id) init {
	self = [super init];
	if (!self)
		return nil;
	
	brightnessText = [[NSString alloc] init];
	brightness = 100;
	
	return self;
}

- (id) initWithDictionary: (NSDictionary *) dict {
	self = [super initWithDictionary: dict];
	if (!self)
		return nil;
	
	brightnessText = [[dict valueForKey: @"parameter"] copy];
	brightness = (unsigned int) [brightnessText floatValue];
	
	// must be between 0 and 100
	brightness = (brightness > 100) ? 100 : brightness;
	brightnessText = [[NSString stringWithFormat: @"%ld", [[NSNumber numberWithFloat:brightness] integerValue]] copy];
	
	return self;
}

- (void) dealloc {
	[brightnessText release];
	
	[super dealloc];
}

- (NSMutableDictionary *) dictionary {
	NSMutableDictionary *dict = [super dictionary];
	
	[dict setObject: [[brightnessText copy] autorelease] forKey: @"parameter"];
	
	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat: NSLocalizedString(@"Set brightness to %@%%.", @""), brightnessText];
}

- (BOOL) execute: (NSString **) errorString {
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"Display brightness cannot be set on this version of macOS. "
			@"Use the keyboard brightness keys, Control Center, or System Settings → Displays, "
			@"or create a Shortcut that adjusts display brightness and run it with a "
			@"ShellScript action (for example: shortcuts run \"Set Display Brightness\").",
			@"Error when DisplayBrightnessAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for the Display Brightness action is the brightness value as a percent between 0 and 100. This action is not available on modern macOS; use keyboard brightness keys, Control Center, System Settings → Displays, or a Shortcuts toggle via a ShellScript action instead.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set display brightness to (percent) (unsupported on this macOS):", @"");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Display Brightness", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"System Preferences", @"");
}

+ (BOOL) shouldWaitForScreensaverExit {
    return YES;
}

+ (BOOL) shouldWaitForScreenUnlock {
    return YES;
}

@end
