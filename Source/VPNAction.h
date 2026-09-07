//
//  VPNAction.h
//  ControlPlane
//
//  Created by Mark Wallis on 18/07/07.
//
//  #133 ARCHIVE (tests / characterization only):
//  ScriptingBridge System Events VPN path is unreliable on modern macOS.
//  Not in the shipping ActionSetController registry and not linked into the
//  ControlPlane app target. Keep gated (isActionApplicableToSystem == NO).
//  NEVPNManager / Shortcuts VPN is deferred — do not re-enable here.
//

#import "Action.h"


@interface VPNAction : Action <ActionWithLimitedOptions> {
	NSString *vpnType;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)dealloc;
- (NSMutableDictionary *)dictionary;

- (NSString *)description;
- (BOOL)execute:(NSString **)errorString;
+ (NSString *)helpText;
+ (NSString *)creationHelpText;

+ (NSArray *)limitedOptions;
- (id)initWithOption:(NSString *)option;

@end
