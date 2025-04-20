//
//  Action+XPCHelperTool.h
//  ControlPlane
//
//  Created by Scott Densmore on 3/30/25.
//

#import "Action.h"
#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

@interface Action (XPCHelperTool)

- (BOOL)helperToolPerformXPCAction:(NSString *)action;
- (BOOL)helperToolPerformXPCAction:(NSString *)action withParameter:(id)parameter;

@end

//NS_ASSUME_NONNULL_END
