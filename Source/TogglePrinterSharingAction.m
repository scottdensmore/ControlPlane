//
//  TogglePrinterSharing.m
//  ControlPlane
//
//  Created by Dustin Rue on 1/15/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "TogglePrinterSharingAction.h"
#import "Action+HelperTool.h"

@implementation TogglePrinterSharingAction

+ (BOOL)isActionApplicableToSystem
{
	// #112: Printer Sharing toggles via the privileged helper are not reliable on
	// Tahoe / modern macOS. Prefer System Settings → General → Sharing.
	return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Enabling Printer Sharing.", @"Act of turning on or enabling Printer Sharing is being performed");
	else
		return NSLocalizedString(@"Disabling Printer Sharing.", @"Act of turning off or disabling Printer Sharing is being performed");
}

- (BOOL) execute: (NSString **) errorString {
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"Printer Sharing cannot be toggled on this version of macOS. "
			@"Use System Settings → General → Sharing, or create a Shortcut "
			@"and run it with the Run Shortcut action.",
			@"Error when TogglePrinterSharingAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for TogglePrinterSharing actions is either \"1\" "
                             "or \"0\", depending on whether you want Printer Sharing "
                             "turned on or off. This action is not available on modern macOS; "
                             "configure Printer Sharing in System Settings → General → Sharing, "
                             "or use a Run Shortcut action.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set Printer Sharing (unsupported on this macOS)", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle Printer Sharing", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Sharing", @"");
}


@end
