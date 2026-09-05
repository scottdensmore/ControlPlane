//
//  Action+HelperTool.m
//  ControlPlane
//
//  Thin façade: privileged work goes through Action+XPCHelperTool → CPXPCService
//  (SMJobBless) → CPHelperTool. Legacy BetterAuthorizationSample / in-app SMJobBless
//  code was removed in #28; do not resurrect it here.
//

#import "Action+HelperTool.h"
#import "Action+XPCHelperTool.h"

@implementation Action (HelperTool)

- (BOOL)helperToolPerformAction:(NSString *)action
{
    return [self helperToolPerformAction:action withParameter:nil];
}

- (BOOL)helperToolPerformAction:(NSString *)action withParameter:(id)parameter
{
    return [self helperToolPerformXPCAction:action withParameter:parameter];
}

@end
