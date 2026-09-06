//
//  RunShortcutAction.m
//  ControlPlane
//
//  Created for issue #34 (Milestone A): invoke a Shortcuts shortcut by name or ID.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//
//  Invocation: typed NSTask argv to /usr/bin/shortcuts (no shell). The public
//  `shortcuts run <name-or-id>` CLI has shipped since macOS 12; we gate on the
//  binary existing so the action is hidden if Apple ever removes it.
//

#import "DSLogger.h"
#import "RunShortcutAction.h"

static NSString * const kShortcutsCLIPath = @"/usr/bin/shortcuts";

@implementation RunShortcutAction {
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
	return [NSString stringWithFormat:NSLocalizedString(@"Run Shortcut '%@'.", @""),
		shortcutNameOrID];
}

- (BOOL)execute:(NSString **)errorString {
	NSString *trimmed = [shortcutNameOrID stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmed.length == 0) {
		if (errorString) {
			*errorString = NSLocalizedString(@"Cannot run Shortcut: name or identifier is empty.", @"");
		}
		return NO;
	}

	if (![RunShortcutAction isActionApplicableToSystem]) {
		if (errorString) {
			*errorString = NSLocalizedString(
				@"Cannot run Shortcut: the shortcuts command-line tool is not available on this Mac.",
				@"");
		}
		return NO;
	}

	NSTask *task = [[NSTask alloc] init];
	task.launchPath = kShortcutsCLIPath;
	// Typed argv — never go through /bin/sh.
	task.arguments = @[ @"run", trimmed ];
	task.standardOutput = [NSPipe pipe];
	task.standardError = [NSPipe pipe];

	@try {
		[task launch];
		[task waitUntilExit];
	} @catch (NSException *exception) {
		DSLog(@"Failed to launch shortcuts CLI for '%@': %@", trimmed, exception);
		if (errorString) {
			*errorString = [NSString stringWithFormat:
				NSLocalizedString(@"Failed to run Shortcut '%@' (could not launch shortcuts).", @""),
				trimmed];
		}
		return NO;
	}

	if (task.terminationStatus != 0) {
		NSData *errData = [[task.standardError fileHandleForReading] readDataToEndOfFile];
		NSString *errText = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
		DSLog(@"shortcuts run '%@' exited %d: %@", trimmed, task.terminationStatus, errText ?: @"");
		if (errorString) {
			*errorString = [NSString stringWithFormat:
				NSLocalizedString(@"Failed to run Shortcut '%@'. Check the name/ID in the Shortcuts app.", @""),
				trimmed];
		}
		return NO;
	}

	DSLog(@"Finished running Shortcut '%@'", trimmed);
	return YES;
}

+ (NSString *)helpText {
	return NSLocalizedString(
		@"The parameter for Run Shortcut is the Shortcut name or identifier "
		@"as shown in the Shortcuts app (or `shortcuts list`). ControlPlane "
		@"invokes `/usr/bin/shortcuts run` with a typed argument list (no shell).",
		@"");
}

+ (NSString *)creationHelpText {
	return NSLocalizedString(@"Run Shortcut named:", @"");
}

+ (NSString *)friendlyName {
	return NSLocalizedString(@"Run Shortcut", @"");
}

+ (NSString *)menuCategory {
	return NSLocalizedString(@"System", @"");
}

@end
