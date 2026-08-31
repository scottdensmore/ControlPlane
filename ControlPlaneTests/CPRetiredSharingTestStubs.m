//
//  CPRetiredSharingTestStubs.m
//  ControlPlaneTests
//
//  Minimal Action/ToggleableAction stubs so retired sharing action tests
//  do not link the full ActionSetController registry from Action.m.
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

+ (BOOL)isActionApplicableToSystem
{
    return YES;
}

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    type = [@"" retain];
    context = [@"" retain];
    when = [@"Arrival" retain];
    delay = [[NSNumber numberWithDouble:0] retain];
    enabled = [[NSNumber numberWithBool:YES] retain];
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if (!(self = [self init])) {
        return nil;
    }
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
    if (!(self = [super init])) {
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

@end
