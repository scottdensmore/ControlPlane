//
//  main.m
//  ControlPlane
//
//  Created by David Symonds on 30/08/06.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	@autoreleasepool {
		// LSUIElement agents are not reliably attachable under XCUITest. When the
		// UITest harness sets CPUITestRunning=1, become a regular app early so
		// XCUIApplication can get a process ID and query prefs.window (#202).
		if ([[[NSProcessInfo processInfo] environment][@"CPUITestRunning"] isEqualToString:@"1"]) {
			[NSApplication sharedApplication];
			[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		}
	}
	return NSApplicationMain(argc, (const char **)argv);
}
