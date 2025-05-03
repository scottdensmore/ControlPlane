//
//	DefaultBrowserAction.m
//	ControlPlane
//
//	Created by David Jennes on 03/09/11.
//	Copyright 2011. All rights reserved.
//

#import "DefaultBrowserAction.h"

@interface DefaultBrowserAction (Private)

+ (id) idToName: (NSString *) bundleID;

@end

@implementation DefaultBrowserAction

- (id) init {
	self = [super init];
	if (!self)
		return nil;
	
	app = [[NSString alloc] init];
    [self setControlPlaneAsURLHandler];
	
	return self;
}

- (id) initWithDictionary: (NSDictionary *) dict {
	self = [super initWithDictionary: dict];
	if (!self)
		return nil;
	
	app = [[dict valueForKey: @"parameter"] copy];
    [self setControlPlaneAsURLHandler];

	
	return self;
}

- (id) initWithOption: (NSString *) option {
	self = [super init];
	if (!self)
		return nil;
	
	app = [option copy];
    [self setControlPlaneAsURLHandler];
	
	return self;
}

- (void) dealloc {
	[app release];
	[super dealloc];
}

- (void) setControlPlaneAsURLHandler {
    // Get current default browser using modern API
    NSURL *httpURL = [NSURL URLWithString:@"http://example.com"];
    NSURL *currentBrowserURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:httpURL];
    NSString *currentBrowserID = nil;
    
    if (currentBrowserURL) {
        NSBundle *currentBrowserBundle = [NSBundle bundleWithURL:currentBrowserURL];
        currentBrowserID = [currentBrowserBundle bundleIdentifier];
    }
    
    NSString *ourBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    if (!currentBrowserID || ![[currentBrowserID lowercaseString] isEqualToString:[ourBundleID lowercaseString]]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"You are adding or have triggered a Default Browser Action but ControlPlane is not currently set as the system wide default web browser. For the Default Browser Action feature to work properly ControlPlane must be set as the system's default web browser. ControlPlane will take the URL and then pass it to the browser of your choice. You may be asked to confirm this choice if you are using OS X 10.10 (Yosemite) or higher. Please select 'Use ControlPlane' if prompted." , @"")];
        [self performSelectorOnMainThread:@selector(runModal) withObject:alert waitUntilDone:false];
        [alert release];
        
        LSSetDefaultHandlerForURLScheme((CFStringRef) @"https", (CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);
        LSSetDefaultRoleHandlerForContentType(kUTTypeHTML, kLSRolesViewer, (CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);
        LSSetDefaultRoleHandlerForContentType(kUTTypeURL, kLSRolesViewer, (CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);
        LSSetDefaultRoleHandlerForContentType(kUTTypeFileURL, kLSRolesViewer, (CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);
        LSSetDefaultRoleHandlerForContentType(kUTTypeText, kLSRolesViewer, (CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);

    }
    LSSetDefaultHandlerForURLScheme((CFStringRef) @"http", (CFStringRef) [[NSBundle mainBundle] bundleIdentifier]);
}

- (NSMutableDictionary *) dictionary {
	NSMutableDictionary *dict = [super dictionary];
	
	[dict setObject: [[app copy] autorelease] forKey: @"parameter"];
	
	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat: NSLocalizedString(@"Setting default browser to %@", @""), app];
}

- (BOOL) execute: (NSString **) errorString {
    [[NSUserDefaults standardUserDefaults] setValue:app forKey:@"currentDefaultBrowser"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    return YES;
    
}

+ (NSString *) helpText {
	return NSLocalizedString(@"The parameter for DefaultBrowser actions is the ID (bundle) "
							 "of the new default browser.", @"");
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
