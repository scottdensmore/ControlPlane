//
//  HostAvailabilityEvidenceSource.m
//  ControlPlane
//
//  Created by Dustin Rue on 8/1/13.
//  Modernized to Network.framework (nw_connection) for issue #121.
//

#import "HostAvailabilityEvidenceSource.h"
#import "RuleType.h"
#import "DSLogger.h"

#import <Network/Network.h>


@implementation HostAvailabilityEvidenceSource

- (id)init
{
	if (!(self = [super initWithNibNamed:@"HostAvailability"]))
		return nil;

	self.monitoredHosts = [NSMutableDictionary dictionary];
	return self;
}

- (id)initForMatchingTests
{
	if (!(self = [super initWithPanel:nil]))
		return nil;

	self.monitoredHosts = [NSMutableDictionary dictionary];
	return self;
}

- (void)dealloc
{
	[self stop];
}

- (NSString *)description
{
	return NSLocalizedString(@"Create rules based on whether a hostname or IP address is reachable on the network.", @"");
}

- (void)setHost:(NSString *)host available:(BOOL)available
{
	if ([host length] == 0)
		return;

	@synchronized (self) {
		NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:self.monitoredHosts[host] ?: @{}];
		entry[@"available"] = @(available);
		NSMutableDictionary *hosts = [self.monitoredHosts mutableCopy] ?: [NSMutableDictionary dictionary];
		hosts[host] = entry;
		self.monitoredHosts = hosts;
		[self setDataCollected:YES];
	}
}

- (void)updateAvailability:(BOOL)available forHost:(NSString *)host
{
	@synchronized (self) {
		NSDictionary *existing = self.monitoredHosts[host];
		if (!existing)
			return;

		BOOL previous = [existing[@"available"] boolValue];
		if (previous == available)
			return;

		NSMutableDictionary *entry = [existing mutableCopy];
		entry[@"available"] = @(available);
		NSMutableDictionary *hosts = [self.monitoredHosts mutableCopy];
		hosts[host] = entry;
		self.monitoredHosts = hosts;
		DSLog(@"host %@ availability -> %@", host, available ? @"YES" : @"NO");
	}
}

- (void)start
{
	@synchronized (self) {
		NSArray *myRules = [self myRules];
		for (NSDictionary *rule in myRules) {
			NSString *host = rule[@"parameter"];
			if ([host length] > 0)
				[self addMonitoredHost:host];
		}
		running = YES;
		dataCollected = YES;
	}
}

- (void)addMonitoredHost:(NSString *)hostToMonitor
{
	if ([hostToMonitor length] == 0)
		return;

	@synchronized (self) {
		if (self.monitoredHosts[hostToMonitor][@"connection"] != nil)
			return;

		nw_endpoint_t endpoint = nw_endpoint_create_host([hostToMonitor UTF8String], "443");
		if (!endpoint) {
			DSLog(@"failed to create endpoint for host %@", hostToMonitor);
			return;
		}

		nw_parameters_t parameters = nw_parameters_create_secure_tcp(NW_PARAMETERS_DISABLE_PROTOCOL,
									   NW_PARAMETERS_DEFAULT_CONFIGURATION);
		if (!parameters) {
			DSLog(@"failed to create parameters for host %@", hostToMonitor);
			return;
		}

		nw_connection_t connection = nw_connection_create(endpoint, parameters);
		if (!connection) {
			DSLog(@"failed to create connection for host %@", hostToMonitor);
			return;
		}

		nw_connection_set_queue(connection, dispatch_get_main_queue());

		__weak typeof(self) weakSelf = self;
		NSString *hostKey = [hostToMonitor copy];

		nw_connection_set_path_changed_handler(connection, ^(nw_path_t path) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			if (!strongSelf)
				return;
			BOOL available = (nw_path_get_status(path) == nw_path_status_satisfied);
			[strongSelf updateAvailability:available forHost:hostKey];
		});

		nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			if (!strongSelf)
				return;
			(void)error;
			if (state == nw_connection_state_ready) {
				[strongSelf updateAvailability:YES forHost:hostKey];
			} else if (state == nw_connection_state_failed) {
				[strongSelf updateAvailability:NO forHost:hostKey];
			}
		});

		NSMutableDictionary *hosts = [self.monitoredHosts mutableCopy] ?: [NSMutableDictionary dictionary];
		hosts[hostToMonitor] = [@{
			@"available" : @NO,
			@"connection" : connection
		} mutableCopy];
		self.monitoredHosts = hosts;

		DSLog(@"monitoring host %@", hostToMonitor);
		nw_connection_start(connection);
	}
}

- (IBAction)closeSheetWithOK:(id)sender
{
	if ([self validatePanelParams]) {
		[super closeSheetWithOK:sender];
	}
}

- (BOOL)validatePanelParams
{
	NSString *param = [self.hostOrIp stringValue];
	param = [param stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self.hostOrIp setStringValue:param];

	if ([param length] == 0) {
		[RuleType alertOnInvalidParamValueWith:NSLocalizedString(@"Host name cannot be empty", @"")];
		return NO;
	}

	return YES;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	NSString *param = [self.hostOrIp stringValue];
	[dict setValue:param forKey:@"parameter"];
	if (![dict objectForKey:@"description"]) {
		[dict setValue:param forKey:@"description"];
	}

	[self addMonitoredHost:param];
	return dict;
}

- (void)stop
{
	@synchronized (self) {
		[self.monitoredHosts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stopFlag) {
			(void)stopFlag;
			nw_connection_t connection = obj[@"connection"];
			if (connection) {
				nw_connection_cancel(connection);
				DSLog(@"stopped monitoring %@", key);
			}
		}];
		[self.monitoredHosts removeAllObjects];
		[self setDataCollected:NO];
		running = NO;
	}
}

- (NSString *)getSuggestionLeadText:(NSString *)type
{
	(void)type;
	return NSLocalizedString(@"Enter hostname or IP address", @"In rule-adding dialog");
}

- (void)writeToPanel:(NSDictionary *)dict usingType:(NSString *)type
{
	[super writeToPanel:dict usingType:type];
	NSString *param = dict[@"parameter"];
	if (param)
		[self.hostOrIp setStringValue:param];
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule
{
	NSString *host = rule[@"parameter"];
	if ([host length] == 0)
		return NO;

	@synchronized (self) {
		return [self.monitoredHosts[host][@"available"] boolValue];
	}
}

- (NSString *)name
{
	return @"HostAvailability";
}

- (NSString *)friendlyName
{
	return NSLocalizedString(@"Host Availability", @"");
}

@end
