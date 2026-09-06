//
//  ToggleFirewallAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 10/20/11.
//  Copyright (c) 2011. All rights reserved.
//
//  Inspired by - http://krypted.com/mac-os-x/command-line-alf-redux/
//

#import "ToggleFirewallAction.h"
#import "Action+HelperTool.h"

@implementation ToggleFirewallAction

+ (BOOL)isActionApplicableToSystem
{
	// #112: Application firewall toggles via the privileged helper are unreliable
	// on modern macOS. Prefer System Settings → Network → Firewall (or a Shortcut).
	return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Enabling Firewall.", @"Act of turning on or enabling the firewall is being performed");
	else
		return NSLocalizedString(@"Disabling Firewall.", @"Act of turning off or disabling the firewall is being performed");
}

- (BOOL) execute: (NSString **) errorString {
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"Firewall cannot be toggled on this version of macOS. "
			@"Use System Settings → Network → Firewall, Control Center, "
			@"or create a Shortcut that adjusts the firewall and run it with "
			@"the Run Shortcut action.",
			@"Error when ToggleFirewallAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for the Firewall action is either \"1\" "
                             "or \"0\", depending on whether you want to enable or disable the firewall. "
                             "This action is not available on modern macOS; configure the firewall in "
                             "System Settings → Network → Firewall, or use a Run Shortcut action.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Turn Firewall (unsupported on this macOS)", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle Firewall", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Networking", @"");
}

@end
