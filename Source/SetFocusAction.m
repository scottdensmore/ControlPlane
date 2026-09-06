//
//  SetFocusAction.m
//  ControlPlane
//
//  Issue #113: invoke a Shortcuts shortcut that sets Focus (typed argv, no shell).
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "DSLogger.h"
#import "SetFocusAction.h"

static NSString * const kShortcutsCLIPath = @"/usr/bin/shortcuts";

@implementation SetFocusAction {
	NSString *shortcutNameOrID;
}

+ (BOOL)isActionApplicableToSystem {
	return [[NSFileManager defaultManager] isExecutableFileAtPath:kShortcutsCLIPath];
}

- (id)init {
	self = [super init];
	if (!self) {
		return nil;
	}
	shortcutNameOrID = @"";
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
	self = [super initWithDictionary:dict];
	if (!self) {
		return nil;
	}
	shortcutNameOrID = [dict[@"parameter"] copy] ?: @"";
	return self;
}

- (NSMutableDictionary *)dictionary {
	NSMutableDictionary *dict = [super dictionary];
	dict[@"parameter"] = [shortcutNameOrID copy] ?: @"";
	return dict;
}

- (NSString *)description {
	return [NSString stringWithFormat:NSLocalizedString(@"Set Focus via Shortcut '%@'.", @""),
		shortcutNameOrID];
}

- (BOOL)execute:(NSString **)errorString {
	NSString *trimmed = [shortcutNameOrID stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmed.length == 0) {
		if (errorString) {
			*errorString = NSLocalizedString(
				@"Cannot set Focus: Shortcut name or identifier is empty. "
				@"Create a Shortcut that uses Set Focus, then enter its name.",
				@"");
		}
		return NO;
	}

	if (![SetFocusAction isActionApplicableToSystem]) {
		if (errorString) {
			*errorString = NSLocalizedString(
				@"Cannot set Focus: the shortcuts command-line tool is not available on this Mac.",
				@"");
		}
		return NO;
	}

	NSTask *task = [[NSTask alloc] init];
	task.launchPath = kShortcutsCLIPath;
	task.arguments = @[ @"run", trimmed ];
	task.standardOutput = [NSPipe pipe];
	task.standardError = [NSPipe pipe];

	@try {
		[task launch];
		[task waitUntilExit];
	} @catch (NSException *exception) {
		DSLog(@"Failed to launch shortcuts CLI for Focus '%@': %@", trimmed, exception);
		if (errorString) {
			*errorString = [NSString stringWithFormat:
				NSLocalizedString(@"Failed to set Focus via Shortcut '%@' (could not launch shortcuts).", @""),
				trimmed];
		}
		return NO;
	}

	if (task.terminationStatus != 0) {
		NSData *errData = [[task.standardError fileHandleForReading] readDataToEndOfFile];
		NSString *errText = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
		DSLog(@"shortcuts run (Focus) '%@' exited %d: %@", trimmed, task.terminationStatus, errText ?: @"");
		if (errorString) {
			*errorString = [NSString stringWithFormat:
				NSLocalizedString(
					@"Failed to set Focus via Shortcut '%@'. "
					@"Create a Shortcut that uses Set Focus and check the name in the Shortcuts app.",
					@""),
				trimmed];
		}
		return NO;
	}

	DSLog(@"Finished Set Focus via Shortcut '%@'", trimmed);
	return YES;
}

+ (NSString *)helpText {
	return NSLocalizedString(
		@"The parameter for Set Focus is the name or identifier of a Shortcut that "
		@"sets the desired Focus mode (create it in the Shortcuts app with the system "
		@"Set Focus action). ControlPlane invokes `/usr/bin/shortcuts run` with a typed "
		@"argument list (no shell) and does not write private Notification Center preferences.",
		@"");
}

+ (NSString *)creationHelpText {
	return NSLocalizedString(@"Set Focus via Shortcut named:", @"");
}

+ (NSString *)friendlyName {
	return NSLocalizedString(@"Set Focus", @"");
}

+ (NSString *)menuCategory {
	return NSLocalizedString(@"System", @"");
}

@end
