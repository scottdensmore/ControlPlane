//
//  Action+XPCHelperTool.m
//  ControlPlane
//
//  Created by Scott Densmore on 3/30/25.
//

#import "Action+XPCHelperTool.h"
#import "CPHelperToolProtocol.h"
#import "CPXPCServiceProtocol.h"
#import "CPAuthorization.h"
#import "../CPHelperTool/CPHelperCommon.h"
#import "../Common/CPCommonConstants.h"

#include <ServiceManagement/ServiceManagement.h>

@interface Action (XPCHelperTool_Private)

//@property (atomic, copy, readwrite) NSData *authorization;

- (NSXPCConnection *)helperToolConnection:(NSXPCListenerEndpoint *)endpoint;
- (NSXPCConnection *)xpcServiceConnection;

- (void)authorize;
- (BOOL)installHelperTool;

- (BOOL)enableTimeMachine;
- (BOOL)disableTimeMachine;
- (BOOL)startBackupTimeMachineBackup;
- (BOOL)stopBackupTimeMachineBackup;

- (BOOL)enableInternetSharing;
- (BOOL)disableInternetSharing;

- (BOOL)enableFirewall;
- (BOOL)disableFirewall;

- (BOOL)setDisplaySleepMinutes:(NSInteger)minutes;

- (BOOL)enablePrinterSharing;
- (BOOL)disablePrinterSharing;

- (BOOL)enableAFPFileSharing;
- (BOOL)disableAFPFileSharing;
- (BOOL)enableSMBFileSharing;
- (BOOL)disableSMBFileSharing;

- (BOOL)enableTFTP;
- (BOOL)disableTFTP;

- (BOOL)enableFTP;
- (BOOL)disableFTP;

- (BOOL)enableWebSharing;
- (BOOL)disableWebSharing;


- (BOOL)enableRemoteLogin;
- (BOOL)disableRemoteLogin;

@end

@implementation Action (XPCHelperTool)

- (BOOL) authorize {
    //    static AuthorizationRef authRef;
    //    static dispatch_once_t authOnceToken;
    //    dispatch_once(&authOnceToken, ^{
    //        OSStatus                    err;
    //        AuthorizationExternalForm   extForm;
    //        err = AuthorizationCreate(NULL, NULL, 0, &authRef);
    //        if (err == errAuthorizationSuccess) {
    //            err = AuthorizationMakeExternalForm(authRef, &extForm);
    //        }
    //        if (err == errAuthorizationSuccess) {
    //            self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    //        }
    //        if (authRef) {
    //            [CPAuthorization setupAuthorizationRights:authRef];
    //        }
    //    });
    
    
    __block BOOL success = YES;
    
    static dispatch_once_t authOnceToken;
    dispatch_once(&authOnceToken, ^{
        [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
            NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
            success = NO;
            authOnceToken = 0;
        }] setupAuthorizationRights];
    });
    
    return success;
}

- (NSXPCConnection *)helperToolConnection:(NSXPCListenerEndpoint *)endpoint {
    static NSXPCConnection *helperConnection;
    static dispatch_once_t helperOnceToken;
    dispatch_once(&helperOnceToken, ^{
        helperConnection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
        helperConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CPHelperToolProtocol)];
        
        // Set up error handling
        helperConnection.invalidationHandler = ^{
            // Connection was invalidated - could attempt to reconnect here
            NSLog(@"Helper Tool connection invalidated");
            helperConnection = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                helperOnceToken = 0; // Allow recreation of connection on next call
            });
        };
        
        helperConnection.interruptionHandler = ^{
            // Connection was interrupted - could attempt to reconnect here
            NSLog(@"Helper Tool connection interrupted");
        };
        
        [helperConnection resume];
    });
    
    return helperConnection;
}

- (NSXPCConnection *)xpcServiceConnection {
    static NSXPCConnection *xpcConnection;
    static dispatch_once_t xpcOnceToken;
    dispatch_once(&xpcOnceToken, ^{
        xpcConnection = [[NSXPCConnection alloc] initWithServiceName:kXPCServiceName];
        xpcConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CPXPCServiceProtocol)];
        
        // Set up error handling
        xpcConnection.invalidationHandler = ^{
            // Connection was invalidated - could attempt to reconnect here
            NSLog(@"XPC Service connection invalidated");
            xpcConnection = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                xpcOnceToken = 0; // Allow recreation of connection on next call
            });
        };
        
        xpcConnection.interruptionHandler = ^{
            // Connection was interrupted - could attempt to reconnect here
            NSLog(@"XPC Service connection interrupted");
        };
        
        [xpcConnection resume];
    });
    
    return xpcConnection;
}

- (BOOL) installHelperTool {
    __block NSError* error = nil;
    __block BOOL needToInstall = YES;
    __block BOOL success = YES;
    
    NSDictionary* installedHelperJobData = (NSDictionary*)SMJobCopyDictionary(kSMDomainSystemLaunchd, (CFStringRef)kHelperToolMachServiceName);
    
    if (installedHelperJobData != nil) {
        [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
            NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
            error = xpcProxyError;
            success = NO;
        }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
            [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
                NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
                error = helperProxyError;
                success = NO;
            }] getVersionWithReply:^(NSString *version) {
                if (![version isEqualToString:@"2.0.0.1"]) {
                    needToInstall = YES;
                }
            }];
        }];
        
        needToInstall = NO;
        CFRelease((__bridge CFDictionaryRef)installedHelperJobData);
    }
    
    if (needToInstall == YES) {
        [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
            NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
            error = xpcProxyError;
            success = NO;
        }] installHelperToolWithReply:^(NSError * replyError) {
            if (replyError == nil) {
                NSLog(@"installed helper tool successfuly");
            } else {
                NSLog(@"Failed to install privileged helper: %@", [replyError description]);
                error = replyError;
                success = NO;
            }
        }];
    }
    
    if (success == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"Error", @"Error")];
            [alert setInformativeText:[NSString stringWithFormat:@"Failed to install privileged helper: %@", [error description]]];
            [alert addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
            [alert runModal];
            [alert release];
        });
    }
    
    return success;
}

#pragma mark Perform Actions

- (BOOL)helperToolPerformXPCAction:(NSString *)action {
    return [self helperToolPerformXPCAction:action withParameter:nil];
}

- (BOOL)helperToolPerformXPCAction:(NSString *)action withParameter:(id)parameter {
    __block BOOL result = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self authorize];
    
    if (![self installHelperTool]) {
        dispatch_release(semaphore);
        return result;
    }
    
    if ([action isEqualToString:kCPHelperEnableTMCommand]) {
        result = [self enableTimeMachine];
    } else if ([action isEqualToString:kCPHelperDisableTMCommand]) {
        result = [self disableTimeMachine];
    } else if ([action isEqualToString:kCPHelperStartBackupTMCommand]) {
        result = [self startTimeMachineBackup];
    } else if ([action isEqualToString:kCPHelperStopBackupTMCommand]) {
        result = [self stopTimeMachineBackup];
    } else if ([action isEqualToString:kCPHelperEnableISCommand]) {
        result = [self enableInternetSharing];
    } else if ([action isEqualToString:kCPHelperDisableISCommand]) {
        result = [self disableInternetSharing];
    } else if ([action isEqualToString:kCPHelperEnableFirewallCommand]) {
        result = [self enableFirewall];
    } else if ([action isEqualToString:kCPHelperDisableFirewallCommand]) {
        result = [self disableFirewall];
    } else if ([action isEqualToString:kCPHelperSetDisplaySleepTimeCommand]) {
        result = [self setDisplaySleepMinutes:[parameter integerValue]];
    } else if ([action isEqualToString:kCPHelperEnablePrinterSharingCommand]) {
        result = [self enablePrinterSharing];
    } else if ([action isEqualToString:kCPHelperDisablePrinterSharingCommand]) {
        result = [self disablePrinterSharing];
    } else if ([action isEqualToString:kCPHelperEnableAFPFileSharingCommand]) {
        result = [self enableAFPFileSharing];
    } else if ([action isEqualToString:kCPHelperDisableAFPFileSharingCommand]) {
        result = [self disableAFPFileSharing];
    } else if ([action isEqualToString:kCPHelperEnableSMBFileSharingCommand]) {
        result = [self enableSMBFileSharing];
    } else if ([action isEqualToString:kCPHelperDisableSMBFileSharingCommand]) {
        result = [self disableSMBFileSharing];
    } else if ([action isEqualToString:kCPHelperEnableTFTPCommand]) {
        result = [self enableTFTP];
    } else if ([action isEqualToString:kCPHelperDisableTFTPCommand]) {
        result = [self disableTFTP];
    } else if ([action isEqualToString:kCPHelperEnableFTPCommand]) {
        result = [self enableFTP];
    } else if ([action isEqualToString:kCPHelperDisableFTPCommand]) {
        result = [self disableFTP];
    } else if ([action isEqualToString:kCPHelperEnableWebSharingCommand]) {
        result = [self enableWebSharing];
    } else if ([action isEqualToString:kCPHelperDisableWebSharingCommand]) {
        result = [self disableWebSharing];
    } else if ([action isEqualToString:kCPHelperEnableRemoteLoginCommand]) {
        result = [self enableRemoteLogin];
    } else if ([action isEqualToString:kCPHelperDisableRemoteLoginCommand]) {
        result = [self disableRemoteLogin];
    } else {
        NSLog(@"Unsupported action: %@", action);
        
        dispatch_release(semaphore);
        
        return result;
    }
    
    // Wait for the action to complete
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    
    dispatch_release(semaphore);
    
    return result;
}

#pragma mark Time Machine Commands

- (BOOL) enableTimeMachine {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableTimeMachineAuthorization:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable time machine : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL) disableTimeMachine {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableTimeMachineAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable time machine : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL) startTimeMachineBackup {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] startBackupTimeMachineAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to start time machine backup : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL) stopTimeMachineBackup {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] stopBackupTimeMachineAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to stop time machine backup : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark Internet Sharing Commands

- (BOOL) enableInternetSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableInternetSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable Internet Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL) disableInternetSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableInternetSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable Internet Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark Firewall Commands

- (BOOL)enableFirewall {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableFirewallAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable the Firewall : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableFirewall {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableFirewallAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable the Firewall : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - Display Settings Commands

- (BOOL)setDisplaySleepMinutes:(NSInteger)minutes; {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] setDisplaySleepTime:minutes authorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to set display sleep time : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - Printer Sharing Commands

- (BOOL)enablePrinterSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enablePrinterSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable Printer Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disablePrinterSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disablePrinterSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disble Printer Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - File Sharing Commands

- (BOOL)enableAFPFileSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableAFPFileSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable AFP File Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableAFPFileSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableAFPFileSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable AFP File Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)enableSMBFileSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableSMBFileSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable SMB File Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableSMBFileSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableSMBFileSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable SMB File Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - TFTP Commands

- (BOOL)enableTFTP {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableTFTPAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable TFTP : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableTFTP {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableTFTPAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable TFTP : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - FTP Commands

- (BOOL)enableFTP {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableFTPAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable FTP : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableFTP {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableTFTPAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable FTP : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - Web Sharing Commands

- (BOOL)enableWebSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableWebSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable Web Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableWebSharing {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableWebSharingAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable Web Sharing : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

#pragma mark - Remote Login Commands

- (BOOL)enableRemoteLogin {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] enableRemoteLoginAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to enable Remote Login : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}

- (BOOL)disableRemoteLogin {
    __block NSError* error = nil;
    __block BOOL success = YES;
    
    [[self.xpcServiceConnection remoteObjectProxyWithErrorHandler:^(NSError * xpcProxyError) {
        NSLog(@"Failed to conect to xpc service : %@", [xpcProxyError description]);
        error = xpcProxyError;
        success = NO;
    }] connectWithEndpointAndAuthorizationReply:^(NSXPCListenerEndpoint * connectReplyEndpoint, NSData * connectReplyAuthorization) {
        [[[self helperToolConnection:connectReplyEndpoint] remoteObjectProxyWithErrorHandler:^(NSError * helperProxyError) {
            NSLog(@"Failed to conect to helper tool : %@", [helperProxyError description]);
            error = helperProxyError;
            success = NO;
        }] disableRemoteLoginAuthorizaiton:connectReplyAuthorization withReply:^(BOOL commandSuccess, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to disable Remote Login : %@", [error description]);
            }
            success = success;
        }];
    }];
    
    return success;
}


@end
