//
//  TimeMachineDestinationAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 1/23/12.
//  Copyright (c) 2012 ControlPlane. All rights reserved.
//

#import "TimeMachineDestinationAction.h"
#import "DSLogger.h"

@implementation TimeMachineDestinationAction

@synthesize destinationVolumePath;

+ (BOOL)isActionApplicableToSystem
{
    // Time Machine destination switching is implemented by AppleScripting the
    // Tedium companion (com.scottdensmore.Tedium). Upstream dustinrue/Tedium is
    // archived (last push 2015); tediumapp.com no longer resolves (NXDOMAIN).
    // No Sequoia-maintained companion found under scottdensmore or local siblings.
    // Gate until a supported companion or in-app replacement exists (#44).
    return NO;
}

- (id)init
{
	if (!(self = [super init]))
		return nil;
    
	destinationVolumePath = [[NSString alloc] init];
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if (!(self = [super initWithDictionary:dict]))
		return nil;
    
	destinationVolumePath = [[dict valueForKey:@"parameter"] copy];
    
	return self;
}

- (void)dealloc
{
    [destinationVolumePath release];
	[super dealloc];
}

- (NSMutableDictionary *)dictionary
{
	NSMutableDictionary *dict = [super dictionary];
    
	[dict setObject:[[destinationVolumePath copy] autorelease] forKey:@"parameter"];
    
	return dict;
}

- (NSString *)description
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting Time Machine destination to '%@'.", @""),
            destinationVolumePath];
}

- (BOOL) execute: (NSString **) errorString {
    if (errorString != NULL) {
        *errorString = NSLocalizedString(
            @"Time Machine Destination cannot be changed on this version of macOS. "
            @"This action requires the Tedium companion app, which is not available for macOS 15.",
            @"Error when TimeMachineDestinationAction runs without Tedium support");
    }
    return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for TimeMachine actions is the name of the "
							 "new Time Machine backup destination. This action is not "
							 "available on modern macOS; it requires the Tedium companion "
							 "app, which is not maintained for macOS 15.", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Set Time Machine's backup destination (unsupported on this macOS)", @"");
}

+ (NSArray *) limitedOptions {
    // Gated: do not probe for Tedium or offer a download link to a dead site.
    return [NSArray array];
}

- (id)initWithOption:(NSString *)option
{
	self = [super init];
	[destinationVolumePath autorelease];
	destinationVolumePath = [option copy];
	return self;
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Change Time Machine Destination", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Time Machine", @"");
}

@end
