//
//  ToggleFTPAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 3/26/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "ToggleFTPAction.h"

@implementation ToggleFTPAction

+ (BOOL)isActionApplicableToSystem
{
    return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Enabling FTP Service.", @"Act of turning on or enabling FTP Service is being performed");
	else
		return NSLocalizedString(@"Disabling FTP Service.", @"Act of turning off or disabling FTP Service is being performed");
}

- (BOOL) execute: (NSString **) errorString {
    if (errorString != NULL) {
        *errorString = NSLocalizedString(@"FTP sharing is not supported on this version of macOS.",
                                         @"Error when a retired sharing action runs on modern macOS");
    }
    return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for ToggleFTP actions is either \"1\" "
                             "or \"0\", depending on whether you want FTP Service "
                             "turned on or off.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set FTP Service", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle FTP Service", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Sharing", @"");
}

@end
