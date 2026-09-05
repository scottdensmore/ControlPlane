//
//  ScreenSaverPasswordAction.m
//  ControlPlane
//
//  Created by David Symonds on 7/06/07.
//

#import "ScreenSaverPasswordAction.h"

@implementation ScreenSaverPasswordAction

+ (BOOL)isActionApplicableToSystem
{
    // Sequoia Lock Screen ("Require password after …") is managed via sysadminctl
    // / login-keychain state, not com.apple.screensaver askForPassword. Writing the
    // old preference is a silent no-op relative to System Settings. Do not shell
    // sysadminctl with a password from ControlPlane.
    return NO;
}

- (NSString *)description
{
	if (turnOn)
		return NSLocalizedString(@"Enabling screen saver password.", @"");
	else
		return NSLocalizedString(@"Disabling screen saver password.", @"");
}

- (BOOL)execute:(NSString **)errorString
{
    if (errorString != NULL) {
        *errorString = NSLocalizedString(
            @"Screen Saver Password cannot change Lock Screen settings on this version of macOS. "
            @"Use System Settings → Lock Screen instead.",
            @"Error when ScreenSaverPasswordAction runs on modern macOS");
    }
    return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for ScreenSaverPasswordAction actions is either \"1\" "
				 "or \"0\", depending on whether you want your screen saver password "
				 "enabled or disabled. This action is not available on modern macOS; "
				 "configure Lock Screen in System Settings instead.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Toggle screen saver password (unsupported on this macOS)", @"");
}

+ (NSArray *)limitedOptions
{
	return [NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"option",
			NSLocalizedString(@"Enable screen saver password", @""), @"description", nil],
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"option",
			NSLocalizedString(@"Disable screen saver password", @""), @"description", nil],
		nil];
}

+ (NSString *)friendlyName {
    return NSLocalizedString(@"Screen Saver Password", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"System Preferences", @"");
}

+ (BOOL)shouldWaitForScreensaverExit {
    return YES;
}

+ (BOOL)shouldWaitForScreenUnlock {
    return YES;
}

@end
