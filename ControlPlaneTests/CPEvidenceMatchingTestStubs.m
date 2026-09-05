//
//  CPEvidenceMatchingTestStubs.m
//  ControlPlaneTests
//
//  Minimal EvidenceSource base so logic tests can link rule matching without
//  EvidenceSource.m's EvidenceSourceSetController registry.
//

#import "EvidenceSource.h"

@implementation EvidenceSource

+ (NSPanel *)getPanelFromNibNamed:(NSString *)name instantiatedWithOwner:(id)owner
{
    (void)name;
    (void)owner;
    return nil;
}

- (id)initWithPanel:(NSPanel *)initPanel
{
    if ([[self class] isEqualTo:[EvidenceSource class]]) {
        [NSException raise:@"Abstract Class Exception"
                    format:@"Error, attempting to instantiate EvidenceSource directly."];
    }

    if (!(self = [super init])) {
        return nil;
    }

    running = NO;
    dataCollected = NO;
    startAfterSleep = NO;
    goingToSleep = NO;
    screenIsLocked = NO;
    oldDescription = nil;
    panel = initPanel;

    return self;
}

- (id)initWithNibNamed:(NSString *)name
{
    if (!(self = [self initWithPanel:nil])) {
        return nil;
    }

    panel = [[[self class] getPanelFromNibNamed:name instantiatedWithOwner:self] retain];
    if (!panel) {
        [self release];
        return nil;
    }

    return self;
}

- (void)dealloc
{
    [panel release];
    [oldDescription release];
    [super dealloc];
}

- (BOOL)matchesRulesOfType:(NSString *)type
{
    return [[self typesOfRulesMatched] containsObject:type];
}

- (BOOL)dataCollected
{
    return dataCollected;
}

- (void)setDataCollected:(BOOL)collected
{
    dataCollected = collected;
}

- (BOOL)isRunning
{
    return running;
}

- (NSArray *)typesOfRulesMatched
{
    return [NSArray arrayWithObject:[self name]];
}

- (BOOL)doesRuleMatch:(NSMutableDictionary *)rule
{
    (void)rule;
    return NO;
}

- (NSString *)name
{
    return @"";
}

- (NSString *)friendlyName
{
    return @"";
}

+ (BOOL)isEvidenceSourceApplicableToSystem
{
    return YES;
}

- (void)goingToSleep:(id)arg
{
    (void)arg;
}

- (void)wakeFromSleep:(id)arg
{
    (void)arg;
}

- (void)screenSaverDidBecomeInActive:(NSNotification *)notification
{
    (void)notification;
}

- (void)screenSaverDidBecomeActive:(NSNotification *)notification
{
    (void)notification;
}

- (void)screenDidUnlock:(NSNotification *)notification
{
    (void)notification;
    screenIsLocked = NO;
}

- (void)screenDidLock:(NSNotification *)notification
{
    (void)notification;
    screenIsLocked = YES;
}

- (void)setContextMenu:(NSMenu *)menu
{
    (void)menu;
}

- (NSMutableDictionary *)readFromPanel
{
    return [NSMutableDictionary dictionary];
}

- (void)writeToPanel:(NSDictionary *)dict usingType:(NSString *)type
{
    (void)dict;
    (void)type;
}

@end
