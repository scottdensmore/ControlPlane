//
//  Action+HelperTool.m
//  ControlPlane
//
//  Thin façade: privileged work goes through Action+XPCHelperTool.
//  The helper must already be an Enabled SMAppService daemon; this path does not
//  call SMJobBless. CPXPCService still brokers the existing XPC protocol.
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
