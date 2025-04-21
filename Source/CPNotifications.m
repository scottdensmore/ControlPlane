//
//  CPNotifications.m
//  ControlPlane
//
//  Created by Dustin Rue on 7/27/12.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <UserNotifications/UserNotifications.h>
#import "CPNotifications.h"


@implementation CPNotifications

+ (void)postUserNotification:(NSString *)title withMessage:(NSString *)message
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EnableNotifications"]) {
        [CPNotifications postNotification:[title copy] withMessage:[message copy]];
    }
}

+ (void)postNotification:(NSString *)title withMessage:(NSString *)message
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    // Create the content for the notification
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = message;
    content.sound = [UNNotificationSound defaultSound];
    
    // Create a request with immediate trigger
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                          content:content
                                                                          trigger:nil]; // nil trigger means deliver immediately
    
    // Add the request to the notification center
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to post notification: %@", error);
        }
    }];
}

@end
