//
//  RunShortcutAction.h
//  ControlPlane
//
//  Created for issue #34 (Milestone A): invoke a Shortcuts shortcut by name or ID.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "Action.h"

@interface RunShortcutAction : Action <ActionWithString>

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
