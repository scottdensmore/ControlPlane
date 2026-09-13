//
//  CPSettingsReadModelTokens.m
//  ControlPlane
//

#import "CPSettingsReadModelTokens.h"

@implementation CPSettingsReadModelTokens

+ (NSString *)trimmedStringFromValue:(id)value {
    if (![value isKindOfClass:[NSString class]]) {
        return @"";
    }
    return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSArray<NSDictionary *> *)contextRowsFromOrderedNames:(NSArray<NSString *> *)names {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray arrayWithCapacity:names.count];
    for (NSString *rawName in names) {
        NSString *name = [self trimmedStringFromValue:rawName];
        if (name.length == 0) {
            continue;
        }
        [rows addObject:@{ @"id": name, @"name": name }];
    }
    return rows;
}

+ (NSArray<NSDictionary *> *)evidenceRowsFromDescriptors:(NSArray<NSDictionary *> *)descriptors {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray arrayWithCapacity:descriptors.count];
    for (NSDictionary *descriptor in descriptors) {
        if (![descriptor isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *identifier = [self trimmedStringFromValue:descriptor[@"id"]];
        NSString *name = [self trimmedStringFromValue:descriptor[@"name"]];
        if (identifier.length == 0) {
            continue;
        }
        if (name.length == 0) {
            name = identifier;
        }
        id enabledValue = descriptor[@"enabled"];
        NSNumber *enabled = [enabledValue isKindOfClass:[NSNumber class]] ? enabledValue : @NO;
        [rows addObject:@{ @"id": identifier, @"name": name, @"enabled": enabled }];
    }
    return rows;
}

+ (NSArray<NSDictionary *> *)actionTypeRowsFromDescriptors:(NSArray<NSDictionary *> *)descriptors {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray arrayWithCapacity:descriptors.count];
    for (NSDictionary *descriptor in descriptors) {
        if (![descriptor isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *identifier = [self trimmedStringFromValue:descriptor[@"id"]];
        NSString *name = [self trimmedStringFromValue:descriptor[@"name"]];
        if (identifier.length == 0) {
            continue;
        }
        if (name.length == 0) {
            name = identifier;
        }
        [rows addObject:@{ @"id": identifier, @"name": name }];
    }
    return rows;
}

@end
