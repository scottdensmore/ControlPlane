//
//  CPContextAppIntentTokens.h
//  ControlPlane
//
//  Names the status menu shows for Force Context, so Shortcuts can pick the
//  same labels and resolve them back to a Context.
//

#import <Foundation/Foundation.h>
#import "ContextsDataSource.h"

extern NSString * const CPContextAppIntentErrorDomain;

typedef NS_ENUM(NSInteger, CPContextAppIntentErrorCode) {
    CPContextAppIntentErrorNotReady = 1,
    CPContextAppIntentErrorContextNotFound = 2,
};

@interface CPContextAppIntentTokens : NSObject

/// Force Context menu order. Unique names stay as the name; duplicates use
/// the Parent/Child path so Shortcuts can tell them apart.
+ (NSArray<NSString *> *)tokensForContextsInMenuOrder:(NSArray<Context *> *)contexts;

/// Resolve a Shortcuts/AppleScript token to the context the status menu would select.
+ (Context *)contextMatchingToken:(NSString *)token inMenuOrder:(NSArray<Context *> *)contexts;

+ (NSError *)errorWithCode:(CPContextAppIntentErrorCode)code contextName:(NSString *)name;

@end
