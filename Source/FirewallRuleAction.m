//
//  FirewallRuleAction.m
//  ControlPlane
//
//  Created by Mark Wallis on 17/07/07.
//  Tweaks by David Symonds on 18/07/07.
//

#import "FirewallRuleAction.h"


@interface FirewallRuleAction (Private)

- (BOOL)isEnableRule;
- (NSString *)strippedRuleName;

@end

@implementation FirewallRuleAction

static NSLock *sharedLock = nil;

+ (void)initialize
{
	sharedLock = [[NSLock alloc] init];
}

+ (BOOL)isActionApplicableToSystem
{
	// #33: Per-rule firewall prefs (com.apple.sharing.firewall) are long dead.
	// ToggleFirewall via helper remains the supported on/off path.
	return NO;
}

- (BOOL)isEnableRule
{
	return ([ruleName characterAtIndex:0] == '+');
}

- (NSString *)strippedRuleName
{
	return [ruleName substringFromIndex:1];
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	ruleName = [[NSString alloc] init];

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if (!(self = [super initWithDictionary:dict]))
		return nil;

	ruleName = [[dict valueForKey:@"parameter"] copy];

	return self;
}

- (void)dealloc
{
	[ruleName release];

	[super dealloc];
}

- (NSMutableDictionary *)dictionary
{
	NSMutableDictionary *dict = [super dictionary];

	[dict setObject:[[ruleName copy] autorelease] forKey:@"parameter"];

	return dict;
}

- (NSString *)description
{
	NSString *name = [self strippedRuleName];

	if ([self isEnableRule])
		return [NSString stringWithFormat:NSLocalizedString(@"Enabling Firewall Rule '%@'.", @""), name];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Disabling Firewall Rule '%@'.", @""), name];
}

- (BOOL)execute:(NSString **)errorString {
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"Firewall Rule actions are not supported on this version of macOS. "
			@"Use Toggle Firewall to enable or disable the application firewall, "
			@"or configure rules in System Settings → Network → Firewall.",
			@"Error when FirewallRuleAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for FirewallRule action is the name of the "
				 "firewall rule you wish to modify, prefixed with '+' or '-' to "
				 "enable or disable it, respectively. This action is not available "
				 "on modern macOS; use Toggle Firewall or System Settings instead.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Set firewall rule (unsupported on this macOS)", @"");
}

+ (NSArray *)limitedOptions
{
	// Locate the firewall preferences dictionary
	NSDictionary *dict = (NSDictionary *) CFPreferencesCopyAppValue(CFSTR("firewall"), CFSTR("com.apple.sharing.firewall"));
	[dict autorelease];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[dict count]];

	NSEnumerator *en = [dict keyEnumerator];
	NSString *name;
	while ((name = [en nextObject])) {
		NSString *enableOpt = [NSString stringWithFormat:@"+%@", name];
		NSString *disableOpt = [NSString stringWithFormat:@"-%@", name];
		NSString *enableDesc = [NSString stringWithFormat:NSLocalizedString(@"Enable %@", @"In FirewallRuleAction"), name];
		NSString *disableDesc = [NSString stringWithFormat:NSLocalizedString(@"Disable %@", @"In FirewallRuleAction"), name];

		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			enableOpt, @"option", enableDesc, @"description", nil]];
		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			disableOpt, @"option", disableDesc, @"description", nil]];
	}

	return opts;
}

- (id)initWithOption:(NSString *)option
{
	self = [super init];
	[ruleName autorelease];
	ruleName = [option copy];
	return self;
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Firewall Rule", @"");
}

@end
