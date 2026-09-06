//
//  WiFiEvidenceSource2.h
//  ControlPlane
//
//  Created by Dustin Rue on 7/10/11.
//  Copyright 2011 Dustin Rue. All rights reserved.
//
//  Bug fixes and improvements by Vladimir Beloborodov (VladimirTechMan) in Jul 2013.
//

#import <CoreLocation/CoreLocation.h>
#import "GenericEvidenceSource.h"

@interface WiFiEvidenceSourceCoreWLAN : GenericEvidenceSource


@property BOOL currentNetworkIsSecure;

- (id)init;
- (id)initForMatchingTests;
- (void)dealloc;

- (void)clearCollectedData;

- (NSString *)name;
- (NSArray *)typesOfRulesMatched;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;
- (NSString *)getSuggestionLeadText:(NSString *)type;
- (NSArray *)getSuggestions;
- (void) getInterfaceStateInfo;

/// Pure helpers for Tahoe Location TCC ↔ SSID evidence (testable without Wi‑Fi hardware).
+ (BOOL)isLocationAuthorizationDeniedOrRestricted:(CLAuthorizationStatus)status;
+ (BOOL)isLocationAuthorizationGranted:(CLAuthorizationStatus)status;
+ (NSString *)ssidUnavailableDueToLocationAuthorizationMessage;

@end
