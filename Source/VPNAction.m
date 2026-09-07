//
//  VPNAction.m
//  ControlPlane
//
//  Created by Mark Wallis on 18/07/07.
//  Updated by Dustin Rue on 8/3/2011.
//
//  #33/#133: Gated orphan — compiled only for ControlPlaneTests. ScriptingBridge
//  System Events VPN path is unreliable; NEVPNManager deferred. Shipping registry
//  must not list VPNAction; isActionApplicableToSystem stays NO.
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
	

	
}

- (NSMutableDictionary *)dictionary
{
	NSMutableDictionary *dict = [super dictionary];

	[dict setObject:[vpnType copy] forKey:@"parameter"];

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
			@"Connect or disconnect VPN from System Settings → VPN, or create a "
			@"Shortcut that uses Set VPN (suggested name: Connect Work VPN) and "
			@"run it with Run Shortcut. See Help → Tips and tricks "
			@"(Shortcuts recipe gallery).",
			@"Error when VPNAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for VPN action is the name of the "
				 "VPN connection you wish to establish or disconnect. "
				 "This action is not available on modern macOS; use System Settings "
				 "or Run Shortcut with a Set VPN Shortcut (suggested name: "
				 "Connect Work VPN). See Help → Tips and tricks "
				 "(Shortcuts recipe gallery).", @"");
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
	vpnType;
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
