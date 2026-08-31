//
//  ToggleFileSharingAction.m
//  ControlPlane
//
//  Created by Dustin Rue on 3/17/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "ToggleFileSharingAction.h"
#import "Action+HelperTool.h"
#import "DSLogger.h"

@implementation ToggleFileSharingAction

+ (BOOL)parameterRequiresAFP:(NSNumber *)parameter
{
    if (parameter == nil) {
        return NO;
    }
    switch ([parameter intValue]) {
        case kCPAFPEnable:
        case kCPAFPAndSMBEnable:
        case kCPAFPDisable:
        case kCPAFPAndSMBDisable:
            return YES;
        default:
            return NO;
    }
}

+ (NSArray *)smbOnlyLimitedOptions
{
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCPSMBEnable], @"option",
             NSLocalizedString(@"SMB Sharing ON", @"Used in toggling actions"), @"description", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCPSMBDisable], @"option",
             NSLocalizedString(@"SMB Sharing OFF", @"Used in toggling actions"), @"description", nil],
            nil];
}

- (NSString *) description {
	if (([turnOn intValue] == kCPAFPEnable) || ([turnOn intValue] == kCPAFPAndSMBEnable) || ([turnOn intValue] == kCPSMBEnable) || ([turnOn intValue] == kCPAFPAndSMBEnable))
		return NSLocalizedString(@"Enabling File Sharing.", @"Act of turning on or enabling File Sharing is being performed");
	else
		return NSLocalizedString(@"Disabling File Sharing.", @"Act of turning off or disabling File Sharing is being performed");
}

- (BOOL) execute: (NSString **) errorString {
    if ([[self class] parameterRequiresAFP:turnOn]) {
        if (errorString != NULL) {
            *errorString = NSLocalizedString(@"AFP file sharing is not supported on this version of macOS.",
                                             @"Error when a legacy AFP file sharing action runs on modern macOS");
        }
        return NO;
    }

    BOOL smbdStatusFailed = NO;
    BOOL enabling = NO;

    if ([turnOn intValue] == kCPSMBEnable) {
        enabling = YES;
        if (![self helperToolPerformAction:kCPHelperEnableSMBFileSharingCommand withParameter:kCPHelperSMBDServiceName]) {
            smbdStatusFailed = YES;
        }
    } else if ([turnOn intValue] == kCPSMBDisable) {
        if (![self helperToolPerformAction:kCPHelperDisableSMBFileSharingCommand withParameter:kCPHelperSMBDServiceName]) {
            smbdStatusFailed = YES;
        }
    }

	if (smbdStatusFailed) {
		if (enabling) {
			*errorString = NSLocalizedString(@"Failed enabling File Sharing.", @"Act of turning off or disabling File Sharing failed");
        } else {
			*errorString = NSLocalizedString(@"Failed disabling File Sharing.", @"Act of turning off or disabling File Sharing failed");
        }
	}

	return !smbdStatusFailed;
}

+ (NSArray *)limitedOptions
{
	return [self smbOnlyLimitedOptions];
}

+ (NSString *) helpText {
	return NSLocalizedString(@"Editing a File Sharing action is not recommended, please delete and add again.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set File Sharing", @"Will be followed by 'on' or 'off'");
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Toggle File Sharing", @"");
}

- (id)initWithOption:(NSObject *)option {
    return [super init];
    
}


- (id)initWithDictionary:(NSDictionary *)dict {

    self = [super initWithDictionary:dict];
    [turnOn autorelease];
    turnOn = [[dict valueForKey:@"parameter"] copy];

    return self;
}
       
+ (NSString *)menuCategory {
    return NSLocalizedString(@"Sharing", @"");
}


@end
