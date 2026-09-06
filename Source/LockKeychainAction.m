//
//	LockKeychainAction.m
//	ControlPlane
//
//	Created by David Jennes on 02/09/11.
//	Copyright 2011. All rights reserved.
//

#import "LockKeychainAction.h"

@implementation LockKeychainAction

+ (BOOL)isActionApplicableToSystem
{
	// #118: SecKeychainLock/Unlock are deprecated and unreliable on modern macOS.
	// Prefer Keychain Access / Shortcuts rather than legacy SecKeychain APIs.
	return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Locking default Keychain.", @"");
	else
		return NSLocalizedString(@"Unlocking default Keychain.", @"");
}

- (BOOL) execute: (NSString **) errorString {
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"Lock/Unlock Keychain is not available on this version of macOS. "
			@"Use Keychain Access, or create a Shortcut and run it with the Run Shortcut action.",
			@"Error when LockKeychainAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for LockKeychain actions is either \"1\" "
							 "or \"0\", depending on whether you want lock or unlock the "
							 "default Keychain. This action is not available on modern macOS; "
							 "use Keychain Access or a Run Shortcut action instead.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Lock or unlock the default Keychain? (unsupported on this macOS)", @"");
}

+ (NSArray *) limitedOptions {
	return [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], @"option",
			 NSLocalizedString(@"Lock", @""), @"description", nil],
			[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: NO], @"option",
			 NSLocalizedString(@"Unlock", @""), @"description", nil],
			nil];
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Lock Keychain", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Keychain", @"");
}

@end
