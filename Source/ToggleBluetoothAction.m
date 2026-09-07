//
//  ToggleBluetoothAction.m
//  ControlPlane
//
//  Created by David Symonds on 1/05/07.
//

#import "ToggleBluetoothAction.h"

@implementation ToggleBluetoothAction

+ (BOOL)isActionApplicableToSystem
{
    // PRIVATE API WARNING (issue #83 / formerly #29):
    // IOBluetoothPreferenceGet/SetControllerPowerState are undocumented private
    // IOBluetooth.framework symbols. There is no public API to toggle Bluetooth
    // radio power (CoreBluetooth is app-scoped only). Gate on Tahoe rather than
    // silently calling private APIs in Release. Prefer Control Center / System
    // Settings, or a Run Shortcut that uses the system Set Bluetooth action.
    return NO;
}

- (NSString *)description
{
	if (turnOn)
		return NSLocalizedString(@"Turning Bluetooth on.", @"");
	else
		return NSLocalizedString(@"Turning Bluetooth off.", @"");
}

- (BOOL)execute:(NSString **)errorString
{
	if (errorString != NULL) {
		*errorString = NSLocalizedString(
			@"Bluetooth cannot be toggled on this version of macOS. "
			@"Use Control Center or System Settings → Bluetooth, or create a "
			@"Shortcut that uses Set Bluetooth (suggested name: Turn Bluetooth On) "
			@"and run it with Run Shortcut. See Help → Tips and tricks "
			@"(Shortcuts recipe gallery).",
			@"Error when ToggleBluetoothAction runs on modern macOS");
	}
	return NO;
}

+ (NSString *)helpText
{
	return NSLocalizedString(@"The parameter for ToggleBluetooth actions is either \"1\" "
				 "or \"0\", depending on whether you want your Bluetooth controller's power "
				 "turned on or off. This action is not available on modern macOS; "
				 "use Control Center, System Settings, or Run Shortcut with a "
				 "Set Bluetooth Shortcut (suggested name: Turn Bluetooth On). "
				 "See Help → Tips and tricks (Shortcuts recipe gallery).", @"");
}

+ (NSString *)creationHelpText
{
	return NSLocalizedString(@"Turn Bluetooth (unsupported on this macOS)", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle Bluetooth", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"System Preferences", @"");
}
@end
