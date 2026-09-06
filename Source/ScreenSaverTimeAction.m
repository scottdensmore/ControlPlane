//
//  ScreenSaverTimeAction.m
//  ControlPlane
//
//  Created by David Symonds on 7/16/07.
//

#import "ScreenSaverTimeAction.h"


@implementation ScreenSaverTimeAction

+ (BOOL)isActionApplicableToSystem
{
    // #120: Writing com.apple.screensaver idleTime and poking
    // com.apple.loginwindow.notify is unverified against System Settings →
    // Screen Saver / Lock Screen on modern macOS. Without interactive
    // confirmation or a public API, prefer gating (same pattern as
    // ScreenSaverPasswordAction). Use System Settings or a Run Shortcut.
    return NO;
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	time = [[NSNumber alloc] initWithInt:0];

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if (!(self = [super initWithDictionary:dict]))
		return nil;

	time = [[dict valueForKey:@"parameter"] copy];

	return self;
}

- (void)dealloc
{
	

	
}

- (NSMutableDictionary *)dictionary
{
	NSMutableDictionary *dict = [super dictionary];

	[dict setObject:[time copy] forKey:@"parameter"];

	return dict;
}

- (NSString *)description
{
	int t = [time intValue];

	if (t == 0)
		return NSLocalizedString(@"Disabling screen saver.", @"");
	else if (t == 1)
		return NSLocalizedString(@"Setting screen saver idle time to 1 minute.", @"");
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Setting screen saver idle time to %d minutes.", @""), t];
}

- (BOOL)execute:(NSString **)errorString
{
    if (errorString != NULL) {
        *errorString = NSLocalizedString(
            @"Screen Saver Time cannot change idle time on this version of macOS. "
            @"Use System Settings → Screen Saver / Lock Screen, or create a Shortcut "
            @"and run it with the Run Shortcut action.",
            @"Error when ScreenSaverTimeAction runs on modern macOS");
    }
    return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for ScreenSaverTimeAction actions is the idle time "
				 "(in minutes) before you want your screen saver to activate. "
				 "This action is not available on modern macOS; configure Screen Saver / "
				 "Lock Screen in System Settings, or use a Run Shortcut instead.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Set screen saver idle time (unsupported on this macOS)", @"");
}

+ (NSArray *)limitedOptions
{
	int opts[] = { 3, 5, 15, 30, 60, 120, 0 };
	int num_opts = sizeof(opts) / sizeof(opts[0]);
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:num_opts];

	int i;
	for (i = 0; i < num_opts; ++i) {
		NSNumber *option = [NSNumber numberWithInt:opts[i]];
		NSString *description;

		if (opts[i] == 0)
			description = NSLocalizedString(@"never", @"Screen saver idle time");
		else if (opts[i] == 1)
			description = NSLocalizedString(@"1 minute", @"Screen saver idle time");
		else
			description = [NSString stringWithFormat:NSLocalizedString(@"%d minutes", @"Screen saver idle time"), opts[i]];

		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			option, @"option",
			description, @"description", nil]];
	}

	return arr;
}

- (id)initWithOption:(NSString *)option
{
	if (!(self = [super init]))
		return nil;

	time;
	time = [[NSNumber alloc] initWithInt:[option intValue]];

	return self;
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Screen Saver Time" , @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"System Preferences", @"");
}

@end
