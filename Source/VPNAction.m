//
//  VPNAction.m
//  ControlPlane
//
//  Created by Mark Wallis on 18/07/07.
//  Updated by Dustin Rue on 8/3/2011.
//
//  #33: ScriptingBridge System Events VPN path is unreliable on modern macOS.
//  NEVPNManager rewrite is out of scope; keep this action gated with clear messaging.
//

#import "VPNAction.h"

@implementation VPNAction

+ (BOOL)isActionApplicableToSystem
{
	// Keep disabled: no Sequoia-ready public path in this slice (NEVPNManager deferred).
	return NO;
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	vpnType = [[NSString alloc] init];

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if (!(self = [super initWithDictionary:dict]))
		return nil;

	vpnType = [[dict valueForKey:@"parameter"] copy];

	return self;
}

- (void)dealloc
{
	[vpnType release];

	[super dealloc];
}

- (NSMutableDictionary *)dictionary
{
	NSMutableDictionary *dict = [super dictionary];

	[dict setObject:[[vpnType copy] autorelease] forKey:@"parameter"];

	return dict;
}

- (NSString *)description
{
	bool enabledPrefix = false;
	if ([vpnType length] > 0 && [vpnType characterAtIndex:0] == '+')
		enabledPrefix = true;
	NSString *strippedVPNType = [vpnType length] > 0 ? [vpnType substringFromIndex:1] : @"";

	if (enabledPrefix == true)
		return [NSString stringWithFormat:NSLocalizedString(@"Connecting to VPN '%@'.", @""),
			strippedVPNType];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Disconnecting from VPN '%@'.", @""),
			strippedVPNType];
}

- (BOOL)execute:(NSString **)errorString
{
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"VPN actions are not supported on this version of macOS. "
			@"Connect or disconnect VPN from System Settings → VPN, or use Shortcuts.",
			@"Error when VPNAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for VPN action is the name of the "
				 "VPN connection you wish to establish or disconnect. "
				 "This action is not available on modern macOS; use System Settings "
				 "or Shortcuts instead.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Establish/Disconnect VPN (unsupported on this macOS)", @"");
}

+ (NSArray *)limitedOptions
{
	return [NSArray array];
}

- (id)initWithOption:(NSString *)option
{
	self = [super init];
	[vpnType autorelease];
	vpnType = [option copy];
	return self;
}

+ (NSString *)friendlyName {
    return NSLocalizedString(@"VPN", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Networking", @"");
}

@end
