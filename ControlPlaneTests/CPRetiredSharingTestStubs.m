//
//  CPRetiredSharingTestStubs.m
//  ControlPlaneTests
//
//  Minimal Action/ToggleableAction implementations so logic tests can exercise
//  registry, toggleable parameter parsing, and retired sharing actions without
//  linking Action.m's ActionSetController (PrefsWindowController / full registry).
//

#import "Action.h"
#import "ToggleableAction.h"
#import "Action+HelperTool.h"

@implementation Action (HelperToolStub)

- (BOOL)helperToolPerformAction:(NSString *)action
{
    (void)action;
    return YES;
}

- (BOOL)helperToolPerformAction:(NSString *)action withParameter:(id)parameter
{
    (void)action;
    (void)parameter;
    return YES;
}

@end

@implementation Action

+ (NSString *)typeForClass:(Class)klass
{
    NSString *className = NSStringFromClass(klass);
    return [className substringToIndex:([className length] - 6)];
}

+ (Class)classForType:(NSString *)type
{
    NSString *classString = [NSString stringWithFormat:@"%@Action", type];
    Class klass = NSClassFromString(classString);
    if (!klass) {
        return nil;
    }
    return klass;
}

+ (Action *)actionFromDictionary:(NSDictionary *)dict
{
    NSString *type = [dict valueForKey:@"type"];
    if (!type) {
        return nil;
    }
    Action *obj = [[[Action classForType:type] alloc] initWithDictionary:dict];
    return [obj autorelease];
}

+ (BOOL)isActionApplicableToSystem
{
    return YES;
}

+ (BOOL)shouldWaitForScreensaverExit
{
    return NO;
}

+ (BOOL)shouldWaitForScreenUnlock
{
    return NO;
}

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    type = [[Action typeForClass:[self class]] retain];
    context = [@"" retain];
    when = [@"Arrival" retain];
    delay = [[NSNumber numberWithDouble:0] retain];
    enabled = [[NSNumber numberWithBool:YES] retain];
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if (!(self = [super init])) {
        return nil;
    }
    type = [[Action typeForClass:[self class]] retain];
    NSString *contextValue = [dict valueForKey:@"context"];
    context = [(contextValue ?: @"") retain];
    NSString *whenValue = [dict valueForKey:@"when"];
    when = [(whenValue ?: @"Arrival") retain];
    delay = [[dict valueForKey:@"delay"] retain] ?: [[NSNumber numberWithDouble:0] retain];
    enabled = [[dict valueForKey:@"enabled"] retain] ?: [[NSNumber numberWithBool:YES] retain];
    return self;
}

- (void)dealloc
{
    [type release];
    [context release];
    [when release];
    [delay release];
    [enabled release];
    [super dealloc];
}

- (NSMutableDictionary *)dictionary
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [[type copy] autorelease], @"type",
            [[context copy] autorelease], @"context",
            [[when copy] autorelease], @"when",
            [[delay copy] autorelease], @"delay",
            [[enabled copy] autorelease], @"enabled",
            nil];
}

- (NSString *)description
{
    return @"";
}

- (BOOL)execute:(NSString **)errorString
{
    (void)errorString;
    return NO;
}

+ (NSString *)helpText
{
    return @"";
}

+ (NSString *)creationHelpText
{
    return @"";
}

+ (NSString *)friendlyName
{
    return @"";
}

+ (NSString *)menuCategory
{
    return @"";
}

@end

@implementation ToggleableAction

- (id)initWithDictionary:(NSDictionary *)dict
{
    if (!(self = [super initWithDictionary:dict])) {
        return nil;
    }
    NSObject *val = [dict valueForKey:@"parameter"];
    if ([val isKindOfClass:[NSNumber class]]) {
        turnOn = [val boolValue];
    } else if ([val isEqual:@"on"] || [val isEqual:@"1"]) {
        turnOn = YES;
    } else {
        turnOn = NO;
    }
    return self;
}

- (id)initWithOption:(NSNumber *)option
{
    self = [super init];
    turnOn = [option boolValue];
    return self;
}

- (NSMutableDictionary *)dictionary
{
    NSMutableDictionary *dict = [super dictionary];
    [dict setObject:[NSNumber numberWithBool:turnOn] forKey:@"parameter"];
    return dict;
}

+ (NSArray *)limitedOptions
{
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"option",
             NSLocalizedString(@"on", @"Used in toggling actions"), @"description", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"option",
             NSLocalizedString(@"off", @"Used in toggling actions"), @"description", nil],
            nil];
}

@end
