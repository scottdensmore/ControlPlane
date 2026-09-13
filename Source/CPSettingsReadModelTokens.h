//
//  CPSettingsReadModelTokens.h
//  ControlPlane
//
//  Pure mapping from ObjC prefs data (context names, evidence source
//  descriptors, action type descriptors) into plain dictionaries that Swift
//  read models can bind to. No app host / NSApp access here so this is
//  unit-testable with fixtures.
//

#import <Foundation/Foundation.h>

@interface CPSettingsReadModelTokens : NSObject

/// Maps ordered Force Context menu names to `@{ @"id":, @"name": }` rows,
/// preserving order and dropping blank/whitespace-only names.
+ (NSArray<NSDictionary *> *)contextRowsFromOrderedNames:(NSArray<NSString *> *)names;

/// Maps evidence source descriptors (`@{ @"id":, @"name":, @"enabled": }`)
/// into read-model rows. Skips entries with a blank id/name; defaults
/// `enabled` to `@NO` when missing.
+ (NSArray<NSDictionary *> *)evidenceRowsFromDescriptors:(NSArray<NSDictionary *> *)descriptors;

/// Maps action type descriptors (`@{ @"id":, @"name": }`) into read-model
/// rows. Skips entries with a blank id/name.
+ (NSArray<NSDictionary *> *)actionTypeRowsFromDescriptors:(NSArray<NSDictionary *> *)descriptors;

@end
