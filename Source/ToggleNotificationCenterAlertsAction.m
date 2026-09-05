//
//  ToggleNotificationCenterAlertsAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 8/13/12.
//
//

#import "ToggleNotificationCenterAlertsAction.h"

@implementation ToggleNotificationCenterAlertsAction

+ (BOOL)isActionApplicableToSystem
{
    // Classic Do Not Disturb via com.apple.notificationcenterui prefs +
    // launchctl stop of notificationcenterui.agent has been broken since Focus
    // replaced DND (Monterey+). Do not write those prefs; use a Shortcuts-based
    // Focus toggle via ShellScript instead (see Help).
    return NO;
}

- (NSString *) description {
	if (turnOn)
		return NSLocalizedString(@"Enabling Notification Center Alerts.", @"Act of turning on or enabling Notification Center Alerts is being performed");
	else
		return NSLocalizedString(@"Disabling Notification Center Alerts.", @"Act of turning off or disabling Notification Center Alerts is being performed");
}

- (BOOL) execute: (NSString **) errorString {
    if (errorString != NULL) {
        *errorString = NSLocalizedString(
            @"Notification Center Alerts / Do Not Disturb cannot be toggled on this version of macOS. "
            @"Create a Shortcut that sets Focus, then run it with a ShellScript action "
            @"(for example: shortcuts run \"Your Focus Shortcut\").",
            @"Error when ToggleNotificationCenterAlertsAction runs on modern macOS");
    }
    return NO;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for ToggleNotificationCenterAlerts actions is either \"1\" "
                             "or \"0\", depending on whether you want Notification Center Alerts "
                             "turned on or off. This action is not available on modern macOS; "
                             "use a Shortcuts Focus toggle via a ShellScript action instead.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set Notification Center Alerts (unsupported on this macOS)", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle Notification Center Alerts", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"System Preferences", @"");
}

@end
