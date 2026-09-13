//
//  CPForceContextUITestHookTests.m
//  ControlPlaneTests
//
//  Source-level contract for issue #244: Force Context in UITests without
//  menu-bar pixel / status-item clicks.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface CPForceContextUITestHookTests : XCTestCase
@end

@implementation CPForceContextUITestHookTests

- (NSString *)srcRoot {
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
	return root;
}

- (NSString *)contentsOfRelativePath:(NSString *)relative {
	NSString *path = [[self srcRoot] stringByAppendingPathComponent:relative];
	NSError *error = nil;
	NSString *text = [NSString stringWithContentsOfFile:path
						   encoding:NSUTF8StringEncoding
						      error:&error];
	XCTAssertNil(error, @"Failed reading %@: %@", path, error);
	XCTAssertNotNil(text);
	return text;
}

- (void)testForceContextAtStartupGoesThroughNamedForceSwitch {
	NSString *controller = [self contentsOfRelativePath:@"Source/CPController.m"];
	XCTAssertTrue([controller containsString:@"Debug ForceContextAtStartup"],
		      @"Harness launch arg maps to Debug ForceContextAtStartup");

	NSRange key = [controller rangeOfString:@"Debug ForceContextAtStartup"];
	XCTAssertTrue(key.location != NSNotFound);
	NSRange search = NSMakeRange(key.location, controller.length - key.location);
	NSRange runtime = [controller rangeOfString:@"stringForKey:@\"Debug ForceContextAtStartup\""
					    options:0
					      range:search];
	XCTAssertTrue(runtime.location != NSNotFound,
		      @"Startup must read Debug ForceContextAtStartup from defaults");

	NSRange applyCall = [controller rangeOfString:@"[self applyForceContextAtStartupIfRequested]"];
	XCTAssertTrue(applyCall.location != NSNotFound,
		      @"Startup dispatch must call applyForceContextAtStartupIfRequested");

	// Implementation (not the private @interface prototype).
	NSRange method = [controller rangeOfString:@"- (void)applyForceContextAtStartupIfRequested {"];
	XCTAssertTrue(method.location != NSNotFound);
	NSString *after = [controller substringFromIndex:method.location];
	NSRange uitest = [after rangeOfString:@"- (void)uitestForceContext:"];
	NSString *body = uitest.location != NSNotFound ? [after substringToIndex:uitest.location] : after;
	XCTAssertTrue([body containsString:@"forceSwitchToContextNamed:"],
		      @"ForceContextAtStartup must use forceSwitchToContextNamed: (menu / App Intent path)");
}

- (void)testUITestDistributedNotificationForceContextIsGated {
	NSString *controller = [self contentsOfRelativePath:@"Source/CPController.m"];
	XCTAssertTrue([controller containsString:@"com.scottdensmore.ControlPlane.UITestForceContext"],
		      @"Distributed notification name must be stable for UITests");
	XCTAssertTrue([controller containsString:@"uitestForceContext:"],
		      @"Must handle the UITest Force Context notification");

	NSRange registerBlock = [controller rangeOfString:@"UITest-only Force Context hook"];
	XCTAssertTrue(registerBlock.location != NSNotFound);
	NSString *tail = [controller substringFromIndex:registerBlock.location];
	NSUInteger windowLen = MIN((NSUInteger)600, tail.length);
	NSString *block = [tail substringToIndex:windowLen];
	XCTAssertTrue([block containsString:@"CPUITestRunning"],
		      @"Force Context distributed listener must register only under CPUITestRunning");
	XCTAssertTrue([block containsString:@"UITestForceContext"],
		      @"Registration must observe UITestForceContext");

	NSRange handler = [controller rangeOfString:@"- (void)uitestForceContext:"];
	XCTAssertTrue(handler.location != NSNotFound);
	NSString *handlerBody = [controller substringFromIndex:handler.location];
	NSRange next = [handlerBody rangeOfString:@"- (void)forceSwitch:"];
	if (next.location != NSNotFound) {
		handlerBody = [handlerBody substringToIndex:next.location];
	}
	XCTAssertTrue([handlerBody containsString:@"CPUITestRunning"],
		      @"Handler must refuse Force Context posts outside CPUITestRunning");
	XCTAssertTrue([handlerBody containsString:@"forceSwitchToContextNamed:"],
		      @"Notification hook must use the same named force-switch path");
}

- (void)testForceContextMenuHasStableAccessibilityIdentifier {
	NSString *controller = [self contentsOfRelativePath:@"Source/CPController.m"];
	XCTAssertTrue([controller containsString:@"status.menu.forceContext"],
		      @"Force Context submenu needs status.menu.forceContext AX id");
}

- (void)testTestingDocsDocumentForceContextHook {
	NSString *docs = [self contentsOfRelativePath:@"docs/TESTING.md"];
	XCTAssertTrue([docs containsString:@"ForceContextAtStartup"] ||
			  [docs containsString:@"Force Context"],
		      @"docs/TESTING.md must document the Force Context UITest hook");
	XCTAssertTrue([docs containsString:@"UITestForceContext"],
		      @"Docs must name the distributed notification");
	XCTAssertTrue([docs containsString:@"#244"] || [docs containsString:@"issue 244"],
		      @"Docs should note #244");
	XCTAssertTrue([docs containsString:@"#206"] || [docs containsString:@"issue 206"],
		      @"Docs should point Force Context journeys at #206");
}

- (void)testDefaultRegistersEmptyForceContextAtStartup {
	NSString *controller = [self contentsOfRelativePath:@"Source/CPController.m"];
	XCTAssertTrue([controller containsString:@"setValue:@\"\" forKey:@\"Debug ForceContextAtStartup\""],
		      @"Default must be empty so normal launches never force a context");
}

@end
