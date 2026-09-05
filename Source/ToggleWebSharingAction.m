//
//  ToggleWebSharingAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 3/27/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "ToggleWebSharingAction.h"

@implementation ToggleWebSharingAction

+ (BOOL)isActionApplicableToSystem
{
    return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Enabling Web Sharing Service.", @"Act of turning on or enabling Web Sharing Service is being performed");
	else
		return NSLocalizedString(@"Disabling Web Sharing Service.", @"Act of turning off or disabling Web Sharing Service is being performed");
}

- (BOOL) execute: (NSString **) errorString {
    if (errorString != NULL) {
        *errorString = NSLocalizedString(@"Web sharing is not supported on this version of macOS.",
                                         @"Error when a retired sharing action runs on modern macOS");
    }
    return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for ToggleWebSharing actions is either \"1\" "
                             "or \"0\", depending on whether you want Web Sharing Service "
                             "turned on or off.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set Web Sharing Service", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle Web Sharing Service", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Sharing", @"");
}


@end
