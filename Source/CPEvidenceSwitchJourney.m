//
//  CPEvidenceSwitchJourney.m
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPEvidenceSwitchJourney.h"
#import "EvidenceSource.h"

@interface CPEvidenceSwitchJourney ()
@property (copy, readwrite, nullable) NSString *activeContextUUID;
@property (copy, readwrite) NSDictionary<NSString *, NSNumber *> *lastGuesses;
@property (copy, readwrite) NSArray<NSDictionary *> *executedActions;
@property (strong) NSMutableDictionary<NSString *, id> *injectedEvidence;
@end

@implementation CPEvidenceSwitchJourney

- (instancetype)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _contexts = @[];
    _rules = @[];
    _actions = @[];
    _minimumConfidenceRequired = 0.75;
    _lastGuesses = @{};
    _executedActions = @[];
    _injectedEvidence = [NSMutableDictionary dictionary];
    return self;
}

- (void)injectEvidenceWithType:(NSString *)type parameter:(id)parameter
{
    if (type.length == 0 || parameter == nil) {
        return;
    }
    self.injectedEvidence[type] = parameter;
}

- (BOOL)evaluate
{
    NSArray<NSDictionary *> *matchingRules = [self matchingRules];
    NSDictionary<NSString *, NSNumber *> *guesses =
        [CPEvidenceSwitchJourney guessesForMatchingRules:matchingRules
                                       contextTreeForUUID:^NSArray<NSDictionary *> *(NSString *contextUUID) {
            return [self contextTreeRootedAt:contextUUID];
        }];
    self.lastGuesses = guesses;

    NSString *candidateUUID = [CPEvidenceSwitchJourney leadingContextUUIDFromGuesses:guesses];
    if (candidateUUID.length == 0) {
        return NO;
    }

    double confidence = [guesses[candidateUUID] doubleValue];
    if (confidence < self.minimumConfidenceRequired) {
        return NO;
    }
    if (self.currentContextUUID.length && [candidateUUID isEqualToString:self.currentContextUUID]) {
        return NO;
    }

    self.currentContextUUID = candidateUUID;
    self.activeContextUUID = candidateUUID;
    [self executeArrivalActionsForContextUUID:candidateUUID];
    return YES;
}

- (NSArray<NSDictionary *> *)matchingRules
{
    NSMutableArray<NSDictionary *> *matching = [NSMutableArray array];
    for (NSDictionary *rule in self.rules) {
        if ([self matchStatusForRule:rule] == RuleDoesMatch) {
            [matching addObject:rule];
        }
    }
    return matching;
}

- (RuleMatchStatusType)matchStatusForRule:(NSDictionary *)rule
{
    RuleMatchStatusType status = RuleMatchStatusIsUnknown;
    NSString *type = rule[@"type"];

    if (self.evidenceMatcher) {
        status = self.evidenceMatcher(rule) ? RuleDoesMatch : RuleDoesNotMatch;
    } else if (type.length && self.injectedEvidence[type] != nil) {
        BOOL hit = [self.injectedEvidence[type] isEqual:rule[@"parameter"]];
        status = hit ? RuleDoesMatch : RuleDoesNotMatch;
    }

    if (([rule[@"negate"] integerValue] == 1) && (status != RuleMatchStatusIsUnknown)) {
        status = (status == RuleDoesMatch) ? RuleDoesNotMatch : RuleDoesMatch;
    }
    return status;
}

- (NSArray<NSDictionary *> *)contextTreeRootedAt:(NSString *)uuid
{
    NSDictionary *root = [self contextForUUID:uuid];
    if (root == nil) {
        return @[];
    }

    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    [self appendContext:root inheritedDepth:nil into:rows];
    return rows;
}

- (void)appendContext:(NSDictionary *)context
         inheritedDepth:(NSNumber *)inheritedDepth
                   into:(NSMutableArray<NSDictionary *> *)rows
{
    NSString *uuid = context[@"uuid"];
    if (uuid.length == 0) {
        return;
    }

    NSNumber *depth = context[@"depth"] ?: inheritedDepth ?: @0;
    [rows addObject:@{ @"uuid": uuid, @"depth": depth }];

    for (NSDictionary *child in self.contexts) {
        if (![child[@"parent"] isEqualToString:uuid]) {
            continue;
        }
        [self appendContext:child inheritedDepth:@([depth intValue] + 1) into:rows];
    }
}

- (nullable NSDictionary *)contextForUUID:(NSString *)uuid
{
    for (NSDictionary *context in self.contexts) {
        if ([context[@"uuid"] isEqualToString:uuid]) {
            return context;
        }
    }
    return nil;
}

- (void)executeArrivalActionsForContextUUID:(NSString *)uuid
{
    NSMutableArray<NSDictionary *> *executed = [NSMutableArray array];
    for (NSDictionary *action in self.actions) {
        if (![action[@"context"] isEqualToString:uuid]) {
            continue;
        }
        if (![action[@"enabled"] boolValue]) {
            continue;
        }
        NSString *when = action[@"when"];
        if (![when isEqualToString:@"Arrival"] && ![when isEqualToString:@"Both"]) {
            continue;
        }

        NSString *error = nil;
        BOOL ok = YES;
        if (self.actionExecutor) {
            ok = self.actionExecutor(action, &error);
        }
        if (ok) {
            [executed addObject:action];
        }
    }
    self.executedActions = executed;
}

+ (NSDictionary<NSString *, NSNumber *> *)guessesForMatchingRules:(NSArray<NSDictionary *> *)matchingRules
                                                contextTreeForUUID:(NSArray<NSDictionary *> * (^)(NSString *contextUUID))treeForUUID
{
    NSMutableDictionary<NSString *, NSNumber *> *guesses = [NSMutableDictionary dictionary];

    for (NSDictionary *currentRule in matchingRules) {
        NSArray<NSDictionary *> *currentContextTree = treeForUUID ? treeForUUID(currentRule[@"context"]) : nil;
        if (currentContextTree.count == 0) {
            continue;
        }

        const int baseDepth = [currentContextTree[0][@"depth"] intValue];
        const double currentRuleConfidence = [currentRule[@"confidence"] doubleValue];

        for (NSDictionary *currentContext in currentContextTree) {
            NSString *uuid = currentContext[@"uuid"];
            if (uuid.length == 0) {
                continue;
            }

            NSNumber *unconfidenceValue = guesses[uuid] ?: @1.0;
            const int depth = [currentContext[@"depth"] intValue];
            double mult = 1.0 - (0.03 * (depth - baseDepth));
            mult *= currentRuleConfidence;
            guesses[uuid] = @([unconfidenceValue doubleValue] * (1.0 - mult));
        }
    }

    NSDictionary<NSString *, NSNumber *> *unconfidence = [guesses copy];
    [unconfidence enumerateKeysAndObjectsUsingBlock:^(NSString *uuid, NSNumber *conf, BOOL *stop) {
        guesses[uuid] = @(1.0 - [conf doubleValue]);
    }];
    return [guesses copy];
}

+ (NSString *)leadingContextUUIDFromGuesses:(NSDictionary<NSString *, NSNumber *> *)guesses
{
    __block NSString *guessUUID = nil;
    __block double guessConf = -1.0;

    [guesses enumerateKeysAndObjectsUsingBlock:^(NSString *uuid, NSNumber *conf, BOOL *stop) {
        const double confidence = [conf doubleValue];
        if (confidence > guessConf) {
            *stop = (confidence >= 1.0);
            guessConf = confidence;
            guessUUID = uuid;
        }
    }];
    return guessUUID;
}

@end
