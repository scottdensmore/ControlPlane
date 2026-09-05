//
//  CPContextTestStubs.m
//  ControlPlaneTests
//
//  Context model without linking ContextsDataSource (prefs UI dependencies).
//

#import "ContextsDataSource.h"

@implementation Context

@synthesize iconColor = _iconColor;

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    CFUUIDRef ref = CFUUIDCreate(NULL);
    _uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, ref);
    CFRelease(ref);

    _parentUUID = [[NSString alloc] init];
    _name = [_uuid copy];

    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _uuid = [dict[@"uuid"] copy];
    _parentUUID = [dict[@"parent"] copy];
    _name = [dict[@"name"] copy];

    NSData *colorData = dict[@"iconColor"];
    if (colorData != nil) {
        NSError *error = nil;
        _iconColor = [(NSColor *)[NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class]
                                                                   fromData:colorData
                                                                      error:&error] copy];
        if (error != nil) {
            NSLog(@"Error unarchiving color data: %@", error);
        }
    }

    return self;
}

- (NSColor *)iconColor
{
    return (_iconColor != nil) ? (_iconColor) : [NSColor blackColor];
}

- (void)setIconColor:(NSColor *)iconColor
{
    _iconColor = [iconColor copy];
}

- (BOOL)isRoot
{
    return ([self.parentUUID length] == 0);
}

- (NSDictionary *)dictionary
{
    if ((_iconColor == nil) || ([_iconColor alphaComponent] == 0.0)) {
        return @{ @"uuid": self.uuid, @"parent": self.parentUUID, @"name": self.name };
    }

    NSError *error = nil;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_iconColor
                                              requiringSecureCoding:NO
                                                              error:&error];
    if (error || !colorData) {
        return @{ @"uuid": self.uuid, @"parent": self.parentUUID, @"name": self.name };
    }

    return @{ @"uuid": self.uuid, @"parent": self.parentUUID, @"name": self.name, @"iconColor": colorData };
}

- (NSComparisonResult)compare:(Context *)ctxt
{
    return [self.name compare:[ctxt name]];
}

- (NSString *)description
{
    return self.name;
}

@end
