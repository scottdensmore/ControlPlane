//
//  CPEvidenceSwitchJourney.h
//  ControlPlane
//
//  Mock-evidence seam for the single-context switch path (#135).
//  Injected evidence → matching rules → confidence threshold → stubbed arrival actions.
//  No live hardware, CoreAudio, or `shortcuts` CLI.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Context dictionaries: uuid (required), name, parent, depth (optional, default 0).
/// Rule dictionaries: type, parameter, context, confidence, optional negate.
/// Action dictionaries: type, context, when, enabled, optional parameter (Mute / RunShortcut).
@interface CPEvidenceSwitchJourney : NSObject

@property (copy) NSArray<NSDictionary *> *contexts;
@property (copy) NSArray<NSDictionary *> *rules;
@property (copy) NSArray<NSDictionary *> *actions;
@property (copy, nullable) NSString *currentContextUUID;
@property (nonatomic) double minimumConfidenceRequired;

/// Optional override. When set, used instead of `injectEvidenceWithType:parameter:`.
/// Typical wiring: an evidence source after `set…ForTesting:` (`-[EvidenceSource doesRuleMatch:]`).
@property (copy, nullable) BOOL (^evidenceMatcher)(NSDictionary *rule);

/// Stub for arrival actions. Tests record Mute / RunShortcut here and must not call `execute:`.
/// Return YES to count the action as executed. Nil means “record success, no side effects.”
@property (copy, nullable) BOOL (^actionExecutor)(NSDictionary *action, NSString * _Nullable * _Nullable error);

@property (copy, readonly, nullable) NSString *activeContextUUID;
@property (copy, readonly) NSDictionary<NSString *, NSNumber *> *lastGuesses;
@property (copy, readonly) NSArray<NSDictionary *> *executedActions;

/// Record one evidence observation. Later injections of the same type replace the parameter.
/// A rule of that type matches only when its parameter equals the injected value.
- (void)injectEvidenceWithType:(NSString *)type parameter:(id)parameter;

/// Match rules against injected evidence, apply the confidence threshold, and run arrival stubs on switch.
/// Returns YES when the active context changes.
- (BOOL)evaluate;

/// Same unconfidence formula as `CPController`'s single-context guess builder.
/// `treeForUUID` returns @{ @"uuid", @"depth" } rows, rooted at the rule's context.
+ (NSDictionary<NSString *, NSNumber *> *)guessesForMatchingRules:(NSArray<NSDictionary *> *)matchingRules
                                                contextTreeForUUID:(NSArray<NSDictionary *> * _Nullable (^)(NSString *contextUUID))treeForUUID;

/// Highest-confidence UUID. Enumeration stops early at 1.0, matching `getMostConfidentContext:`.
+ (nullable NSString *)leadingContextUUIDFromGuesses:(NSDictionary<NSString *, NSNumber *> *)guesses;

@end

NS_ASSUME_NONNULL_END
