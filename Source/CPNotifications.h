//
//  CPNotifications.h
//  ControlPlane
//
//  Created by Dustin Rue on 7/27/12.
//
//

#import <Foundation/Foundation.h>

@interface CPNotifications : NSObject

+ (void)migrateLegacyGrowlPreferenceInDefaults:(NSUserDefaults *)defaults;
+ (void)migrateLegacyGrowlPreferenceIfNeeded;
+ (void)requestAuthorizationIfNeededWithCompletion:(void (^)(BOOL granted))completion;
+ (void)showAuthorizationDeniedAlert;

+ (void)postNotification:(NSString *)title withMessage:(NSString *)message;
+ (void)postUserNotification:(NSString *)title withMessage:(NSString *)message;

@end
