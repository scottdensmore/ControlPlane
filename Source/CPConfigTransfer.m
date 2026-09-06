//
//  CPConfigTransfer.m
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPConfigTransfer.h"

const NSInteger CPConfigTransferSchemaVersion = 1;
NSErrorDomain const CPConfigTransferErrorDomain = @"CPConfigTransferErrorDomain";

@implementation CPConfigTransfer

+ (NSArray<NSString *> *)settingsKeys
{
    static NSArray<NSString *> *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[
            @"Enabled",
            @"MinimumConfidenceRequired",
            @"EnableSwitchSmoothing",
            @"SmoothSwitchCount",
            @"HideStatusBarIcon",
            @"EnableNotifications",
            @"menuBarOption",
            @"UseDefaultContext",
            @"DefaultContext",
            @"EnablePersistentContext",
            @"PersistentContext",
            @"AllowMultipleActiveContexts",
            @"ShowAdvancedPreferences",
            @"UpdateInterval",
            @"WiFiAlwaysScans",
            @"EnableAudioOutputEvidenceSource",
            @"EnableBluetoothEvidenceSource",
            @"EnableDNSEvidenceSource",
            @"EnableFireWireEvidenceSource",
            @"EnableIPAddrEvidenceSource",
            @"EnableLightEvidenceSource",
            @"EnableMonitorEvidenceSource",
            @"EnablePowerEvidenceSource",
            @"EnableRunningApplicationEvidenceSource",
            @"EnableTimeOfDayEvidenceSource",
            @"EnableUSBEvidenceSource",
            @"EnableCoreWLANEvidenceSource",
            @"EnableSleep/WakeEvidenceSource",
            @"EnableCoreLocationSource",
        ];
    });
    return keys;
}

+ (NSError *)errorWithCode:(CPConfigTransferErrorCode)code message:(NSString *)message
{
    NSDictionary *userInfo = nil;
    if (message.length > 0) {
        userInfo = @{ NSLocalizedDescriptionKey: message };
    }
    return [NSError errorWithDomain:CPConfigTransferErrorDomain code:code userInfo:userInfo];
}

+ (NSDictionary *)exportDictionaryFromDefaults:(NSUserDefaults *)defaults
{
    NSParameterAssert(defaults != nil);

    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    for (NSString *key in [self settingsKeys]) {
        id value = [defaults objectForKey:key];
        if (value != nil) {
            settings[key] = value;
        }
    }

    NSArray *contexts = [defaults arrayForKey:@"Contexts"] ?: @[];
    NSArray *rules = [defaults arrayForKey:@"Rules"] ?: @[];
    NSArray *actions = [defaults arrayForKey:@"Actions"] ?: @[];

    NSMutableDictionary *document = [NSMutableDictionary dictionaryWithCapacity:6];
    document[@"schemaVersion"] = @(CPConfigTransferSchemaVersion);
    document[@"exportedAt"] = [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]];
    document[@"contexts"] = contexts;
    document[@"rules"] = rules;
    document[@"actions"] = actions;
    document[@"settings"] = settings;
    return [document copy];
}

+ (BOOL)importDictionary:(NSDictionary *)document
            intoDefaults:(NSUserDefaults *)defaults
                   error:(NSError **)error
{
    NSParameterAssert(defaults != nil);

    if (![document isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document must be a dictionary."];
        }
        return NO;
    }

    id versionValue = document[@"schemaVersion"];
    if (versionValue == nil || ![versionValue respondsToSelector:@selector(integerValue)]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document is missing schemaVersion."];
        }
        return NO;
    }

    NSInteger version = [versionValue integerValue];
    if (version < 1) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document schemaVersion is invalid."];
        }
        return NO;
    }
    if (version > CPConfigTransferSchemaVersion) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorUnsupportedSchemaVersion
                                 message:[NSString stringWithFormat:
                                          @"Unsupported configuration schema version %ld (max %ld).",
                                          (long)version, (long)CPConfigTransferSchemaVersion]];
        }
        return NO;
    }

    id contexts = document[@"contexts"];
    id rules = document[@"rules"];
    id actions = document[@"actions"];
    id settings = document[@"settings"];

    if (contexts != nil && ![contexts isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document contexts must be an array."];
        }
        return NO;
    }
    if (rules != nil && ![rules isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document rules must be an array."];
        }
        return NO;
    }
    if (actions != nil && ![actions isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document actions must be an array."];
        }
        return NO;
    }
    if (settings != nil && ![settings isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration document settings must be a dictionary."];
        }
        return NO;
    }

    [defaults setObject:(contexts ?: @[]) forKey:@"Contexts"];
    [defaults setObject:(rules ?: @[]) forKey:@"Rules"];
    [defaults setObject:(actions ?: @[]) forKey:@"Actions"];

    NSSet *allowedSettings = [NSSet setWithArray:[self settingsKeys]];
    for (NSString *key in (NSDictionary *)(settings ?: @{})) {
        if (![allowedSettings containsObject:key]) {
            continue;
        }
        id value = ((NSDictionary *)settings)[key];
        if (value == nil || value == [NSNull null]) {
            [defaults removeObjectForKey:key];
        } else {
            [defaults setObject:value forKey:key];
        }
    }

    [defaults synchronize];
    return YES;
}

+ (NSData *)exportJSONDataFromDefaults:(NSUserDefaults *)defaults error:(NSError **)error
{
    NSDictionary *document = [self exportDictionaryFromDefaults:defaults];
    NSError *serializationError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:document
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&serializationError];
    if (!data) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorSerialization
                                 message:serializationError.localizedDescription ?: @"JSON serialization failed."];
        }
        return nil;
    }
    return data;
}

+ (BOOL)importJSONData:(NSData *)data intoDefaults:(NSUserDefaults *)defaults error:(NSError **)error
{
    if (data.length == 0) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration JSON data is empty."];
        }
        return NO;
    }

    NSError *serializationError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
    if (![object isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:serializationError.localizedDescription ?: @"Configuration JSON is invalid."];
        }
        return NO;
    }

    return [self importDictionary:(NSDictionary *)object intoDefaults:defaults error:error];
}

+ (NSData *)exportPropertyListDataFromDefaults:(NSUserDefaults *)defaults error:(NSError **)error
{
    NSDictionary *document = [self exportDictionaryFromDefaults:defaults];
    NSError *serializationError = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:document
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&serializationError];
    if (!data) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorSerialization
                                 message:serializationError.localizedDescription ?: @"Property list serialization failed."];
        }
        return nil;
    }
    return data;
}

+ (BOOL)importPropertyListData:(NSData *)data intoDefaults:(NSUserDefaults *)defaults error:(NSError **)error
{
    if (data.length == 0) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:@"Configuration property list data is empty."];
        }
        return NO;
    }

    NSError *serializationError = nil;
    id object = [NSPropertyListSerialization propertyListWithData:data
                                                          options:NSPropertyListImmutable
                                                           format:NULL
                                                            error:&serializationError];
    if (![object isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [self errorWithCode:CPConfigTransferErrorInvalidDocument
                                 message:serializationError.localizedDescription ?: @"Configuration property list is invalid."];
        }
        return NO;
    }

    return [self importDictionary:(NSDictionary *)object intoDefaults:defaults error:error];
}

@end
