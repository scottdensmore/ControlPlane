//
//  CPAuthorization.h
//  ControlPlane
//
//  Created by Scott Densmore on 3/29/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPAuthorization : NSObject

// For a given command selector, return the associated authorization right name.
+ (NSString *)authorizationRightForCommand:(SEL)command;
    
// Set up the default authorization rights in the authorization database.
+ (void)setupAuthorizationRights:(AuthorizationRef)authRef;
    
@end

NS_ASSUME_NONNULL_END
