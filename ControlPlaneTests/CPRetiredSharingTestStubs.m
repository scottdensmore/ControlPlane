//
//  CPRetiredSharingTestStubs.m
//  ControlPlaneTests
//
//  Minimal Action/ToggleableAction stubs so retired sharing action tests
//  do not link the full ActionSetController registry from Action.m.
//

#import "Action.h"
#import "ToggleableAction.h"

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

- (id)initWithOption:(NSNumber *)option
{
    self = [super init];
    turnOn = [option boolValue];
    return self;
}

@end
