//
//  CPDiagnosticsSnapshot.h
//  ControlPlane
//
//  Pure snapshot builder for the Diagnostics prefs pane (#35).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPDiagnosticsSnapshot : NSObject

/// Build a property-list-friendly diagnostics dictionary for UI / tests.
///
/// Expected rule keys: type, description, parameter, context, confidence,
/// cachedStatus (RuleMatchStatusType), optional negate.
/// Expected evidence keys: name, friendlyName, running, dataCollected, summary.
+ (NSDictionary *)snapshotWithCurrentContextName:(nullable NSString *)currentName
                              currentContextPath:(nullable NSString *)currentPath
                              currentContextUUID:(nullable NSString *)currentUUID
                                           rules:(NSArray<NSDictionary *> *)rules
                                  contextGuesses:(NSDictionary<NSString *, NSNumber *> *)guesses
                               contextNameForUUID:(NSString * _Nonnull (^)(NSString *uuid))nameForUUID
                       minimumConfidenceRequired:(double)minimumConfidence
                                 evidenceSources:(NSArray<NSDictionary *> *)evidenceSources;

@end

NS_ASSUME_NONNULL_END
