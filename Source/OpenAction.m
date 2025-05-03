//
//  OpenAction.m
//  ControlPlane
//
//  Created by David Symonds on 3/04/07.
//  Updated by Dustin Rue on 8/28/2012 
//  Updated by Vladimir Beloborodov on 2/07/2013
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "OpenAction.h"
#import "DSLogger.h"

@implementation OpenAction {
	NSString *path;
}

- (id)init {
	self = [super init];
    if (!self) {
		return nil;
    }
    
	path = @"";
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
	self = [super initWithDictionary:dict];
    if (!self) {
		return nil;
    }
    
	path = [dict[@"parameter"] copy];
	return self;
}

- (id)initWithFile:(NSString *)file {
	self = [super init];
    if (!self) {
		return nil;
    }
    
	path = [file copy];
	return self;
}

- (NSMutableDictionary *)dictionary {
	NSMutableDictionary *dict = [super dictionary];
	dict[@"parameter"] = [path copy];
	return dict;
}

- (NSString *)description {
	return [NSString stringWithFormat:NSLocalizedString(@"Opening '%@'.", @""), path];
}

- (NSWorkspaceOpenConfiguration *)launchConfiguration {
    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    configuration.activates = NO;
    return configuration;
}
- (BOOL)execute:(NSString **)errorString {
	NSString *app, *fileType;
    
	if (![[NSWorkspace sharedWorkspace] getInfoForFile:path application:&app type:&fileType]) {
		*errorString = [NSString stringWithFormat:NSLocalizedString(@"Failed opening '%@'.", @""), path];
        return NO;
	}
    
	if ([[fileType uppercaseString] isEqualToString:@"SCPT"]) {
		NSArray *args = [NSArray arrayWithObject:path];
		NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:args];
		[task waitUntilExit];
		if ([task terminationStatus] == 0) {
            return YES;
        }
        
	} else {
        NSBundle *requestedAppBundle = [NSBundle bundleWithPath:path];
        
        // if the requestedAppBundle comes back nil then
        // they are either specifying that an actual file (not an app) be opened
        if (requestedAppBundle != nil) {
            NSString *bundleId = [requestedAppBundle bundleIdentifier];
            @try {
                // Do not "open" an app that is already running
                if (bundleId && [[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleId] count]) {
                    DSLog(@"%@ is already running", bundleId);
                    return YES;
                }
            }
            @catch (NSException *e) {
                DSLog(@"failed to get the bundleidentifier for %@", bundleId);
            }
        }
        
        // whether it is a file or an app, it needs to get opened here
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];

        // Apply any specific configuration settings here if needed
        // configuration.activates = YES;
        // configuration.hides = NO;

        __block BOOL success = NO;
        [[NSWorkspace sharedWorkspace] openURL:fileURL
                                 configuration:configuration
                             completionHandler:^(NSRunningApplication * _Nullable application, NSError * _Nullable error) {
                                 if (error == nil) {
                                     success = YES;
                                 } else {
                                     NSLog(@"Failed to open URL: %@", error);
                                 }
                             }];

        // If you need synchronous behavior, you may need to wait for the completion handler
        // This is a simple approach, but in a real app you might want to use a better mechanism
        // dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        // dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5));

        return success;
	}
	
	*errorString = [NSString stringWithFormat:NSLocalizedString(@"Failed opening '%@'.", @""), path];
	return NO;
}

+ (NSString *)helpText {
	return NSLocalizedString(@"The parameter for Open actions is the full path of the"
                             " object to be opened, such as an application or a document.", @"");
}

+ (NSString *)friendlyName {
    return NSLocalizedString(@"Open File or Application", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Application", @"");
}

@end
