//
//  FirewallRuleAction.h
//  ControlPlane
//
//  Created by Mark Wallis on 17/07/07.
//
//  #133 ARCHIVE (tests / characterization only):
//  Per-rule firewall prefs (com.apple.sharing.firewall) are long dead.
//  Not in the shipping ActionSetController registry and not linked into the
//  ControlPlane app target. Keep gated (isActionApplicableToSystem == NO).
//  Do not re-enable without a public-API rewrite.
//

#import "Action.h"


@interface FirewallRuleAction : Action <ActionWithLimitedOptions> {
	NSString *ruleName;
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
