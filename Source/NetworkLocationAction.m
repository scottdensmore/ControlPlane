//
//  NetworkLocationAction.m
//  ControlPlane
//
//  Created by David Symonds on 4/07/07.
//  Modified by Vladimir Beloborodov (VladimirTechMan) on 12 June 2013.
//  Modified by Vladimir Beloborodov (VladimirTechMan) on 11 May 2014.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <SystemConfiguration/SCNetworkConfiguration.h>
#import <SystemConfiguration/SCPreferences.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>

#import "NetworkLocationAction.h"


@implementation NetworkLocationAction

+ (BOOL)isActionApplicableToSystem {
    // #33: Network Locations UI was removed in Ventura+. scselect -l is gone;
    // SCNetworkSet/scselect can still list legacy sets, but creating and managing
    // locations is no longer a reliable user-facing path on Sequoia. Prefer gate
    // over offering a half-broken action.
    return NO;
}

#pragma mark Utility methods

+ (NSDictionary *)getAllSets {
	NSDictionary *dict = nil;

    SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("ControlPlane"), NULL);
	SCPreferencesLock(prefs, true);

	CFPropertyListRef cfDict = (CFDictionaryRef) SCPreferencesGetValue(prefs, kSCPrefSets);
    if ((cfDict != NULL) && (CFGetTypeID(cfDict) == CFDictionaryGetTypeID())) {
        dict = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)cfDict];
    }

	SCPreferencesUnlock(prefs);
	CFRelease(prefs);

	return dict;
}

#pragma mark -

- (id)initWithOption:(NSString *)option {
	self = [super init];
    if (self) {
        networkLocation = [option copy];
    }
	return self;
}

- (id)init {
	return [self initWithOption:@""];
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super initWithDictionary: dict];
    if (!self) {
        return nil;
    }
    

    networkLocation = dict[@"parameter"];
    
    return self;
}

- (NSMutableDictionary *)dictionary {
	NSMutableDictionary *dict = [super dictionary];
    dict[@"parameter"] = [networkLocation copy];
	return dict;
}

- (NSString *)description {
	return [NSString stringWithFormat:NSLocalizedString(@"Changing network location to '%@'.", @""),
		networkLocation];
}

- (BOOL)isRequiredNetworkLocationAlreadySet {
	BOOL result = NO;
    
    SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("ControlPlane"), NULL);
	SCPreferencesLock(prefs, true);
    
    SCNetworkSetRef currentSet = SCNetworkSetCopyCurrent(prefs);
    if (currentSet) {
        NSString *currentNetworkName = (__bridge NSString *)SCNetworkSetGetName(currentSet);
        result = [currentNetworkName isEqualToString:networkLocation];
        CFRelease(currentSet);
    }
    
    SCPreferencesUnlock(prefs);
    CFRelease(prefs);
    
    return result;
}

- (BOOL)execute:(NSString **)errorString {
    if (errorString != NULL) {
        *errorString = NSLocalizedString(
            @"Network Location cannot be changed on this version of macOS. "
            @"Network Locations were removed from System Settings.",
            @"Error when NetworkLocationAction runs on modern macOS");
    }
    return NO;
}

+ (NSString *)helpText {
	return NSLocalizedString(@"The parameter for NetworkLocation actions is the name of the "
                             "network location to select. This action is not available on modern macOS; "
                             "Network Locations were removed from System Settings.", @"");
}

+ (NSString *)creationHelpText {
	return NSLocalizedString(@"Changing network location (unsupported on this macOS)", @"");
}

+ (NSArray *)limitedOptions {
	NSDictionary *allSets = [[self class] getAllSets];
    NSMutableArray *networkLocationNames = [NSMutableArray arrayWithCapacity:[allSets count]];

    [allSets enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *set, BOOL *stop) {
        if ([set isKindOfClass:[NSDictionary class]]) {
            id userDefinedName = set[(NSString *)kSCPropUserDefinedName];
            if ((userDefinedName != nil) && [userDefinedName isKindOfClass:[NSString class]]) {
                [networkLocationNames addObject:userDefinedName];
            }
        }
    }];
	[networkLocationNames sortUsingSelector:@selector(localizedCompare:)];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[networkLocationNames count]];
	for (NSString *loc in networkLocationNames) {
		[opts addObject:@{ @"option": loc, @"description": loc }];
    }

	return opts;
}

+ (NSString *)friendlyName {
    return NSLocalizedString(@"Network Location", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Networking", @"");
}

@end
