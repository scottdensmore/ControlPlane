//
//  SetFocusAction.h
//  ControlPlane
//
//  Issue #113: Set Focus via a Shortcuts-backed shortcut name (no private NC prefs).
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "Action.h"

@interface SetFocusAction : Action <ActionWithString>

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSMutableDictionary *)dictionary;

- (NSString *)description;
- (BOOL)execute:(NSString **)errorString;
+ (NSString *)helpText;
+ (NSString *)creationHelpText;
+ (NSString *)friendlyName;
+ (NSString *)menuCategory;
+ (BOOL)isActionApplicableToSystem;

@end
