//
//  CPDiagnosticsSnapshot.m
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPDiagnosticsSnapshot.h"
#import "EvidenceSource.h"
#import "SharedNumberFormatter.h"

@implementation CPDiagnosticsSnapshot

+ (NSString *)matchStatusStringForCachedStatus:(id)cachedStatus
{
    RuleMatchStatusType status = (cachedStatus != nil) ? ([cachedStatus intValue]) : RuleMatchStatusIsUnknown;
    switch (status) {
        case RuleDoesMatch:
            return @"match";
        case RuleDoesNotMatch:
            return @"no-match";
        default:
            return @"unknown";
    }
}

+ (NSDictionary *)snapshotWithCurrentContextName:(NSString *)currentName
                              currentContextPath:(NSString *)currentPath
                              currentContextUUID:(NSString *)currentUUID
                                           rules:(NSArray<NSDictionary *> *)rules
                                  contextGuesses:(NSDictionary<NSString *, NSNumber *> *)guesses
                               contextNameForUUID:(NSString * (^)(NSString *uuid))nameForUUID
                       minimumConfidenceRequired:(double)minimumConfidence
                                 evidenceSources:(NSArray<NSDictionary *> *)evidenceSources
{
    NSString *safeCurrentName = currentName.length ? currentName : NSLocalizedString(@"(none)", @"Diagnostics: no current context");
    NSString *safeCurrentPath = currentPath.length ? currentPath : safeCurrentName;

    __block NSString *leadingUUID = nil;
    __block double leadingConf = -1.0;
    [guesses enumerateKeysAndObjectsUsingBlock:^(NSString *uuid, NSNumber *conf, BOOL *stop) {
        double value = [conf doubleValue];
        if (value > leadingConf) {
            leadingConf = value;
            leadingUUID = uuid;
        }
    }];

    NSString *leadingName = leadingUUID ? nameForUUID(leadingUUID) : NSLocalizedString(@"(none)", @"Diagnostics: no leading context");
    if (!leadingName.length) {
        leadingName = leadingUUID ?: NSLocalizedString(@"(none)", @"Diagnostics: no leading context");
    }

    double currentConf = 0.0;
    if (currentUUID.length && guesses[currentUUID] != nil) {
        currentConf = [guesses[currentUUID] doubleValue];
    }

    NSMutableArray *ruleRows = [NSMutableArray arrayWithCapacity:rules.count];
    NSMutableArray *leadingRuleDescriptions = [NSMutableArray array];

    for (NSDictionary *rule in rules) {
        NSString *ctxUUID = [rule[@"context"] description] ?: @"";
        NSString *ctxName = ctxUUID.length ? nameForUUID(ctxUUID) : @"";
        if (!ctxName.length) {
            ctxName = ctxUUID;
        }

        NSString *matchStatus = [self matchStatusStringForCachedStatus:rule[@"cachedStatus"]];
        double ruleConf = [rule[@"confidence"] doubleValue];
        double ctxConf = guesses[ctxUUID] ? [guesses[ctxUUID] doubleValue] : 0.0;
        BOOL isMatch = [matchStatus isEqualToString:@"match"];
        BOOL contributesToLeading = isMatch && leadingUUID.length && [ctxUUID isEqualToString:leadingUUID];

        NSString *desc = rule[@"description"];
        if (![desc isKindOfClass:[NSString class]] || desc.length == 0) {
            desc = [rule[@"parameter"] description] ?: @"";
        }

        NSDictionary *row = @{
            @"type": rule[@"type"] ?: @"",
            @"description": desc,
            @"parameter": [rule[@"parameter"] description] ?: @"",
            @"contextUUID": ctxUUID,
            @"contextName": ctxName,
            @"ruleConfidence": @(ruleConf),
            @"contextConfidence": @(ctxConf),
            @"matchStatus": matchStatus,
            @"negate": @([rule[@"negate"] integerValue] == 1),
            @"contributesToLeading": @(contributesToLeading),
        };
        [ruleRows addObject:row];

        if (contributesToLeading) {
            NSString *type = row[@"type"];
            [leadingRuleDescriptions addObject:[NSString stringWithFormat:@"%@ “%@” (%.0f%%)",
                                                type, desc, ruleConf * 100.0]];
        }
    }

    NSNumberFormatter *pct = [SharedNumberFormatter percentStyleFormatter];
    NSString *leadingPct = [pct stringFromNumber:@(MAX(leadingConf, 0.0))] ?: @"—";
    NSString *currentPct = [pct stringFromNumber:@(currentConf)] ?: @"—";
    NSString *minPct = [pct stringFromNumber:@(minimumConfidence)] ?: @"—";

    NSString *explanation = nil;
    if (!leadingUUID) {
        explanation = NSLocalizedString(@"No matching rules produced a context guess. Check that evidence sources are enabled and collecting data.",
                                        @"Diagnostics explanation when no guesses");
    } else if (currentUUID.length && [leadingUUID isEqualToString:currentUUID]) {
        if (leadingConf + 1e-9 >= minimumConfidence) {
            explanation = [NSString stringWithFormat:
                           NSLocalizedString(@"Current context “%@” leads at %@ (minimum to switch %@). Matching rules: %@.",
                                             @"Diagnostics explanation when current context leads"),
                           safeCurrentName, leadingPct, minPct,
                           leadingRuleDescriptions.count ? [leadingRuleDescriptions componentsJoinedByString:@"; "]
                                                        : NSLocalizedString(@"(none)", @"Diagnostics: no matching rules")];
        } else {
            explanation = [NSString stringWithFormat:
                           NSLocalizedString(@"Current context “%@” is at %@ but below the %@ switch threshold. Leading rules: %@.",
                                             @"Diagnostics explanation when current context is below threshold"),
                           safeCurrentName, leadingPct, minPct,
                           leadingRuleDescriptions.count ? [leadingRuleDescriptions componentsJoinedByString:@"; "]
                                                        : NSLocalizedString(@"(none)", @"Diagnostics: no matching rules")];
        }
    } else if (leadingConf + 1e-9 >= minimumConfidence) {
        explanation = [NSString stringWithFormat:
                       NSLocalizedString(@"Prefer “%@” (%@ confidence) over current “%@” (%@). Minimum to switch is %@. Winning rules: %@.",
                                         @"Diagnostics explanation for mis-switched / pending switch"),
                       leadingName, leadingPct, safeCurrentName, currentPct, minPct,
                       leadingRuleDescriptions.count ? [leadingRuleDescriptions componentsJoinedByString:@"; "]
                                                    : NSLocalizedString(@"(none)", @"Diagnostics: no matching rules")];
    } else {
        explanation = [NSString stringWithFormat:
                       NSLocalizedString(@"No context meets the %@ confidence threshold. Leading guess is “%@” at %@ (current “%@” at %@).",
                                         @"Diagnostics explanation when nothing meets threshold"),
                       minPct, leadingName, leadingPct, safeCurrentName, currentPct];
    }

    return @{
        @"currentContextName": safeCurrentName,
        @"currentContextPath": safeCurrentPath,
        @"currentContextUUID": currentUUID ?: @"",
        @"currentContextConfidence": @(currentConf),
        @"leadingContextName": leadingName,
        @"leadingContextUUID": leadingUUID ?: @"",
        @"leadingContextConfidence": @(MAX(leadingConf, 0.0)),
        @"minimumConfidenceRequired": @(minimumConfidence),
        @"explanation": explanation,
        @"ruleRows": [ruleRows copy],
        @"evidenceSources": [evidenceSources copy] ?: @[],
        @"contextGuesses": [guesses copy] ?: @{},
    };
}

@end
