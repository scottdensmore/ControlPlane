//
//  CPConfigTransfer.h
//  ControlPlane
//
//  Versioned export/import of contexts, rules, actions, and related settings.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Current on-disk schema version for ControlPlane configuration documents.
FOUNDATION_EXPORT const NSInteger CPConfigTransferSchemaVersion;

/// Error domain for configuration transfer failures.
FOUNDATION_EXPORT NSErrorDomain const CPConfigTransferErrorDomain;

typedef NS_ERROR_ENUM(CPConfigTransferErrorDomain, CPConfigTransferErrorCode) {
    CPConfigTransferErrorInvalidDocument = 1,
    CPConfigTransferErrorUnsupportedSchemaVersion = 2,
    CPConfigTransferErrorSerialization = 3,
};

@interface CPConfigTransfer : NSObject

/// Keys written under the document's "settings" dictionary (behavior-relevant prefs).
+ (NSArray<NSString *> *)settingsKeys;

/// Build a property-list-compatible document dictionary from defaults.
+ (NSDictionary *)exportDictionaryFromDefaults:(NSUserDefaults *)defaults;

/// Apply a previously exported document into defaults (replaces contexts/rules/actions/settings).
+ (BOOL)importDictionary:(NSDictionary *)document
            intoDefaults:(NSUserDefaults *)defaults
                   error:(NSError * _Nullable * _Nullable)error;

/// Serialize export as UTF-8 JSON.
+ (nullable NSData *)exportJSONDataFromDefaults:(NSUserDefaults *)defaults
                                          error:(NSError * _Nullable * _Nullable)error;

/// Import from JSON produced by exportJSONDataFromDefaults:.
+ (BOOL)importJSONData:(NSData *)data
          intoDefaults:(NSUserDefaults *)defaults
                 error:(NSError * _Nullable * _Nullable)error;

/// Serialize export as an XML property list.
+ (nullable NSData *)exportPropertyListDataFromDefaults:(NSUserDefaults *)defaults
                                                  error:(NSError * _Nullable * _Nullable)error;

/// Import from a property list (XML or binary) document.
+ (BOOL)importPropertyListData:(NSData *)data
                  intoDefaults:(NSUserDefaults *)defaults
                         error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
