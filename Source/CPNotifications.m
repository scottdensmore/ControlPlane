//
//  CPNotifications.m
//  ControlPlane
//
//  Created by Dustin Rue on 7/27/12.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>
#import "CPNotifications.h"

@implementation CPNotifications

+ (void)migrateLegacyGrowlPreferenceInDefaults:(NSUserDefaults *)defaults
{
    if (defaults == nil) {
        return;
    }
    if ([defaults objectForKey:@"EnableGrowl"] == nil) {
        return;
    }
    if ([defaults objectForKey:@"EnableNotifications"] == nil) {
        [defaults setBool:[defaults boolForKey:@"EnableGrowl"] forKey:@"EnableNotifications"];
    }
    [defaults removeObjectForKey:@"EnableGrowl"];
}

+ (void)migrateLegacyGrowlPreferenceIfNeeded
{
    [self migrateLegacyGrowlPreferenceInDefaults:[NSUserDefaults standardUserDefaults]];
}

+ (void)requestAuthorizationIfNeededWithCompletion:(void (^)(BOOL granted))completion
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized
            || settings.authorizationStatus == UNAuthorizationStatusProvisional) {
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES);
                });
            }
            return;
        }
        if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            return;
        }

        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"Notification authorization request failed: %@", error);
            }
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(granted);
                });
            }
        }];
    }];
}

+ (void)showAuthorizationDeniedAlert
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Notifications Are Disabled",
                                          @"Alert title when notification permission is denied");
    alert.informativeText = NSLocalizedString(@"ControlPlane cannot show notifications until you allow them in System Settings > Notifications.",
                                                @"Alert detail when notification permission is denied");
    [alert addButtonWithTitle:NSLocalizedString(@"Open System Settings", @"Button to open notification settings")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSURL *settingsURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.Notifications-Settings.extension"];
        [[NSWorkspace sharedWorkspace] openURL:settingsURL];
    }
}

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
