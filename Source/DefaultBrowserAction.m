//
//	DefaultBrowserAction.m
//	ControlPlane
//
//	Created by David Jennes on 03/09/11.
//	Copyright 2011. All rights reserved.
//

#import "DefaultBrowserAction.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface DefaultBrowserAction (Private)

+ (id) idToName: (NSString *) bundleID;

@end

@implementation DefaultBrowserAction

- (id) init {
	self = [super init];
	if (!self)
		return nil;
	
	app = [[NSString alloc] init];
	return self;
}

- (id) initWithDictionary: (NSDictionary *) dict {
	self = [super initWithDictionary: dict];
	if (!self)
		return nil;
	
	app = [[dict valueForKey: @"parameter"] copy];
	return self;
}

- (id) initWithOption: (NSString *) option {
	self = [super init];
	if (!self)
		return nil;
	
	app = [option copy];
	return self;
}

- (void) dealloc {
	
}

- (NSMutableDictionary *) dictionary {
	NSMutableDictionary *dict = [super dictionary];
	
	[dict setObject: [app copy] forKey: @"parameter"];
	
	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat: NSLocalizedString(@"Setting default browser to %@", @""), app];
}

- (BOOL) execute: (NSString **) errorString {
	if ([app length] == 0) {
		if (errorString) {
			*errorString = NSLocalizedString(
				@"Default Browser action needs a browser bundle ID. ControlPlane does not change the system handler until you choose one.",
				@"Error when DefaultBrowserAction has no target browser");
		}
		return NO;
	}

	NSString *error = nil;
	if (![self registerControlPlaneAsURLHandler:&error]) {
		if (errorString) {
			*errorString = error ?: NSLocalizedString(
				@"Could not set ControlPlane as the default browser. If macOS asked you to confirm, choose ControlPlane, or pick another evidence path.",
				@"Error when DefaultBrowserAction handler registration is denied");
		}
		return NO;
	}

	[[NSUserDefaults standardUserDefaults] setValue:app forKey:@"currentDefaultBrowser"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	return YES;
}

- (BOOL)registerControlPlaneAsURLHandler:(NSString **)errorString {
	NSString *ourBundleID = [[NSBundle mainBundle] bundleIdentifier];
	if ([ourBundleID length] == 0) {
		if (errorString) {
			*errorString = NSLocalizedString(@"ControlPlane has no bundle identifier; cannot register as a browser handler.", @"");
		}
		return NO;
	}

	OSStatus httpStatus = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"http", (__bridge CFStringRef)ourBundleID);
	OSStatus httpsStatus = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"https", (__bridge CFStringRef)ourBundleID);
	OSStatus htmlStatus = LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)UTTypeHTML.identifier, kLSRolesViewer, (__bridge CFStringRef)ourBundleID);
	OSStatus urlStatus = LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)UTTypeURL.identifier, kLSRolesViewer, (__bridge CFStringRef)ourBundleID);

	if (httpStatus != noErr || httpsStatus != noErr || htmlStatus != noErr || urlStatus != noErr) {
		if (errorString) {
			*errorString = [NSString stringWithFormat:NSLocalizedString(
				@"macOS refused to make ControlPlane the default browser (http %d, https %d). Confirm the prompt if one appeared, or leave the system handler unchanged.",
				@"Error when LSSetDefaultHandler fails"), (int)httpStatus, (int)httpsStatus];
		}
		return NO;
	}
	return YES;
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for DefaultBrowser actions is the bundle ID "
							 "of the browser ControlPlane should open. ControlPlane registers itself "
							 "as the system http/https handler only when the action runs, and only for "
							 "HTML and URL types. If macOS denies that prompt, the action fails and does "
							 "not silently take over.", @"");
}

+ (NSString *) creationHelpText {
	return NSLocalizedString(@"Set default browser to:", @"");
}

+ (NSArray *)limitedOptions {
    // Create a URL with http scheme
    NSURL *httpURL = [NSURL URLWithString:@"http://example.com"];
    
    // Get applications that can open this URL using the recommended API
    NSArray *appURLs = [[NSWorkspace sharedWorkspace] URLsForApplicationsToOpenURL:httpURL];
    
    // No handlers
    if (!appURLs || [appURLs count] == 0)
        return [NSArray array];
    
    NSUInteger total = [appURLs count];
    NSMutableArray *options = [NSMutableArray arrayWithCapacity:total];
    NSString *currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    for (NSURL *appURL in appURLs) {
        NSBundle *appBundle = [NSBundle bundleWithURL:appURL];
        NSString *bundleID = [appBundle bundleIdentifier];
        
        // Skip our own app
        if ([[bundleID lowercaseString] isEqualToString:[currentBundleID lowercaseString]])
            continue;
        
        [options addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           bundleID, @"option",
                           [self idToName:bundleID], @"description", nil]];
    }
    
    return options;
}

+ (NSString *) idToName: (NSString *) bundleID {
    NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier: bundleID];
    NSString *path = [appURL path];
    
    return [[NSFileManager defaultManager] displayNameAtPath: path];
}

+ (NSString *) friendlyName {
    return NSLocalizedString(@"Default Browser", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Web", @"");
}

- (void)handleURL:(NSString *)url {
    NSString *browser = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentDefaultBrowser"];
    
    if (!browser) {
        browser = @"com.apple.Safari";
    }
    
    NSString *decodedURL = [url stringByRemovingPercentEncoding];
    
    // Replace deprecated CFURLCreateStringByAddingPercentEscapes with modern API
    NSString *newURL = [decodedURL stringByAddingPercentEncodingWithAllowedCharacters:
                       [NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURL *urlToOpen = [NSURL URLWithString:newURL];
    
    if (!urlToOpen) {
        NSLog(@"Invalid URL: %@", newURL);
        return;
    }
    
    // Get browser application URL
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *browserURL = [workspace URLForApplicationWithBundleIdentifier:browser];
    
    if (!browserURL) {
        NSLog(@"Browser with bundle ID %@ not found", browser);
        return;
    }
    
    // Create configuration
    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    configuration.activates = YES;
    
    // Open URL with the specified browser
    [workspace openURL:urlToOpen
          configuration:configuration
      completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
          if (error) {
              NSLog(@"Failed to open URL %@ with browser %@: %@", newURL, browser, error);
          }
      }];
}

@end
