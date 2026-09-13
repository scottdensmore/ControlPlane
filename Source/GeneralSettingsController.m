//
//  GeneralSettingsController.m
//  ControlPlane
//

#import "GeneralSettingsController.h"
#import "ControlPlane-Swift.h"

@interface GeneralSettingsController ()
@property (nonatomic, strong) GeneralSettingsViewModel *viewModel;
@property (nonatomic, strong) NSViewController *hostedViewController;
@end

@implementation GeneralSettingsController

- (instancetype)initWithUseNotifications:(BOOL)useNotifications
                             startAtLogin:(BOOL)startAtLogin
                   allowPrivilegedHelper:(BOOL)allowPrivilegedHelper
                   applyUseNotifications:(BOOL (^)(BOOL))applyUseNotifications
                        applyStartAtLogin:(BOOL (^)(BOOL))applyStartAtLogin
               applyAllowPrivilegedHelper:(BOOL (^)(BOOL))applyAllowPrivilegedHelper
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _viewModel = [[GeneralSettingsViewModel alloc] initWithUseNotifications:useNotifications
                                                                startAtLogin:startAtLogin
                                                      allowPrivilegedHelper:allowPrivilegedHelper
                                                      applyUseNotifications:applyUseNotifications
                                                          applyStartAtLogin:applyStartAtLogin
                                                 applyAllowPrivilegedHelper:applyAllowPrivilegedHelper];
    _hostedViewController = [GeneralSettingsHost makeViewControllerWithModel:_viewModel];

    return self;
}

- (NSView *)view
{
    return self.hostedViewController.view;
}

- (void)refreshWithStartAtLogin:(BOOL)startAtLogin allowPrivilegedHelper:(BOOL)allowPrivilegedHelper
{
    [self.viewModel refreshWithStartAtLogin:startAtLogin allowPrivilegedHelper:allowPrivilegedHelper];
}

@end
