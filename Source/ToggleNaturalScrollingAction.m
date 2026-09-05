//
//  ToggleNaturalScrollingAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 3/25/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "ToggleNaturalScrollingAction.h"

@implementation ToggleNaturalScrollingAction

+ (BOOL)isActionApplicableToSystem
{
    // Natural Scrolling toggle requires private CGS API (CGSSetSwipeScrollDirection).
    // Writing com.apple.swipescrolldirection alone does not apply changes to live input
    // on modern macOS. No reliable public API exists on Sequoia.
    return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Enabling Natural Scrolling.", @"Act of turning on or enabling Natural Scrolling is being performed");
	else
		return NSLocalizedString(@"Disabling Natural Scrolling.", @"Act of turning off or disabling Natural Scrolling is being performed");
}

- (BOOL) execute: (NSString **) errorString {
    if (errorString != NULL) {
        *errorString = NSLocalizedString(
            @"Natural Scrolling cannot be toggled on this version of macOS. "
            @"Use System Settings → Trackpad → Natural Scrolling instead.",
            @"Error when ToggleNaturalScrollingAction runs on modern macOS");
    }
    return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for ToggleNaturalScrolling actions is either \"1\" "
                             "or \"0\", depending on whether you want Natural Scrolling "
                             "turned on or off. This action is not available on modern macOS; "
                             "configure Natural Scrolling in System Settings instead.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set Natural Scrolling (unsupported on this macOS)", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle Natural Scrolling", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"System Preferences", @"");
}
@end
