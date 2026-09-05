//
//  CPLoginItemService.h
//  ControlPlane
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

NS_ASSUME_NONNULL_BEGIN

/// Wraps SMAppService.mainAppService for Start at Login.
@interface CPLoginItemService : NSObject

+ (instancetype)sharedService;

/// YES when System Settings will launch the app at login (Enabled).
- (BOOL)isEnabled;

/// YES when the prefs checkbox should appear checked (Enabled or RequiresApproval).
- (BOOL)checkboxOn;

/// Maps SMAppService status to checkbox on/off.
/// Enabled and RequiresApproval → on; NotRegistered / NotFound → off.
+ (BOOL)checkboxStateForStatus:(SMAppServiceStatus)status;

/// Current SMAppService status for the main app.
- (SMAppServiceStatus)status;

/// Enable or disable login launch. On RequiresApproval, opens Login Items settings.
/// Returns YES if the resulting checkbox state matches the requested enabled flag
/// (or RequiresApproval after a successful register attempt).
- (BOOL)setEnabled:(BOOL)enabled error:(NSError * _Nullable * _Nullable)error;

/// Opens System Settings → Login Items (macOS 13+).
+ (void)openLoginItemsSettings;

@end

NS_ASSUME_NONNULL_END
