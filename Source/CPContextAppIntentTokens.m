//
//  CPContextAppIntentTokens.m
//  ControlPlane
//

#import "CPContextAppIntentTokens.h"

NSString * const CPContextAppIntentErrorDomain = @"com.scottdensmore.ControlPlane.AppIntent";

@implementation CPContextAppIntentTokens

+ (NSString *)pathForContext:(Context *)context among:(NSDictionary<NSString *, Context *> *)byUUID {
    NSMutableArray<NSString *> *walk = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    NSString *uuid = context.uuid;
    int limit = 20;

    while (limit > 0 && uuid.length > 0 && ![seen containsObject:uuid]) {
        --limit;
        [seen addObject:uuid];
        Context *current = byUUID[uuid];
        if (current == nil) {
            break;
        }
        [walk addObject:current.name ?: @""];
        uuid = current.parentUUID;
    }

    return [[[walk reverseObjectEnumerator] allObjects] componentsJoinedByString:@"/"];
}

+ (NSDictionary<NSString *, Context *> *)indexByUUID:(NSArray<Context *> *)contexts {
    NSMutableDictionary<NSString *, Context *> *byUUID = [NSMutableDictionary dictionary];
    for (Context *context in contexts) {
        if (context.uuid.length > 0) {
            byUUID[context.uuid] = context;
        }
    }
    return byUUID;
}

+ (NSCountedSet<NSString *> *)nameCounts:(NSArray<Context *> *)contexts {
    NSCountedSet<NSString *> *counts = [NSCountedSet set];
    for (Context *context in contexts) {
        if (context.name.length > 0) {
            [counts addObject:context.name];
        }
    }
    return counts;
}

+ (NSString *)tokenForContext:(Context *)context
                         path:(NSString *)path
                    nameCounts:(NSCountedSet<NSString *> *)nameCounts
                    usedTokens:(NSMutableSet<NSString *> *)usedTokens {
    NSString *token = nil;
    if (context.name.length > 0 && [nameCounts countForObject:context.name] == 1) {
        token = context.name;
    } else if (path.length > 0) {
        token = path;
    } else {
        token = context.uuid;
    }

    if (token.length == 0) {
        token = context.uuid ?: @"";
    }

    if ([usedTokens containsObject:token] && context.uuid.length > 0) {
        token = [NSString stringWithFormat:@"%@ (%@)", token, context.uuid];
    }
    if (token.length > 0) {
        [usedTokens addObject:token];
    }
    return token;
}

+ (NSArray<NSString *> *)tokensForContextsInMenuOrder:(NSArray<Context *> *)contexts {
    NSDictionary<NSString *, Context *> *byUUID = [self indexByUUID:contexts];
    NSCountedSet<NSString *> *nameCounts = [self nameCounts:contexts];
    NSMutableSet<NSString *> *usedTokens = [NSMutableSet set];
    NSMutableArray<NSString *> *tokens = [NSMutableArray arrayWithCapacity:contexts.count];

    for (Context *context in contexts) {
        NSString *path = [self pathForContext:context among:byUUID];
        NSString *token = [self tokenForContext:context path:path nameCounts:nameCounts usedTokens:usedTokens];
        if (token.length > 0) {
            [tokens addObject:token];
        }
    }
    return tokens;
}

+ (Context *)contextMatchingToken:(NSString *)token inMenuOrder:(NSArray<Context *> *)contexts {
    NSString *trimmed = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0 || contexts.count == 0) {
        return nil;
    }

    NSDictionary<NSString *, Context *> *byUUID = [self indexByUUID:contexts];
    NSCountedSet<NSString *> *nameCounts = [self nameCounts:contexts];
    NSMutableSet<NSString *> *usedTokens = [NSMutableSet set];

    Context *pathMatch = nil;
    for (Context *context in contexts) {
        NSString *path = [self pathForContext:context among:byUUID];
        NSString *menuToken = [self tokenForContext:context path:path nameCounts:nameCounts usedTokens:usedTokens];
        if ([menuToken isEqualToString:trimmed]) {
            return context;
        }
        if (path.length > 0 && [path isEqualToString:trimmed]) {
            pathMatch = context;
        }
    }
    return pathMatch;
}

+ (NSError *)errorWithCode:(CPContextAppIntentErrorCode)code contextName:(NSString *)name {
    NSString *title = name.length > 0 ? name : @"";
    NSString *description = nil;
    if (code == CPContextAppIntentErrorNotReady) {
        description = @"ControlPlane is not ready to switch contexts yet.";
    } else if (title.length > 0) {
        description = [NSString stringWithFormat:@"No ControlPlane context named “%@”.", title];
    } else {
        description = @"No ControlPlane context was specified.";
    }

    return [NSError errorWithDomain:CPContextAppIntentErrorDomain
                                code:code
                            userInfo:@{ NSLocalizedDescriptionKey: description }];
}

@end
