//
//  LocalizationCatalogTests.m
//  ControlPlaneTests
//
//  Issue #131: Focus, Power, Run Shortcut, Settings, and gated-action
//  strings must exist in every shipping locale and not stay English-only.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface LocalizationCatalogTests : XCTestCase
@end

@implementation LocalizationCatalogTests

- (NSString *)srcRoot {
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
	return root;
}

- (NSArray<NSString *> *)sliceSourceFiles {
	return @[
		@"Source/FocusEvidenceSource.m",
		@"Source/SetFocusAction.m",
		@"Source/RunShortcutAction.m",
		@"Source/PowerEvidenceSource.m",
		@"Source/AttachedPowerAdapterEvidenceSource.m",
		@"Source/CPPrefsSettingsShellController.m",
		@"Source/ToggleFirewallAction.m",
		@"Source/TogglePrinterSharingAction.m",
		@"Source/LockKeychainAction.m",
		@"Source/ScreenSaverTimeAction.m",
		@"Source/ScreenSaverPasswordAction.m",
		@"Source/ToggleNotificationCenterAlertsAction.m",
		@"Source/ToggleBluetoothAction.m",
		@"Source/VPNAction.m",
		@"Source/DefaultBrowserAction.m",
		@"Source/CPHelperDaemonService.m",
	];
}

- (NSArray<NSString *> *)shippingLocales {
	return @[ @"en", @"da-DK", @"de", @"fr", @"it", @"pt-BR", @"pt-PT" ];
}

- (NSString *)objcUnescape:(NSString *)raw {
	NSMutableString *out = [NSMutableString string];
	for (NSUInteger i = 0; i < raw.length; i++) {
		unichar c = [raw characterAtIndex:i];
		if (c == '\\' && i + 1 < raw.length) {
			unichar n = [raw characterAtIndex:i + 1];
			if (n == 'n') { [out appendString:@"\n"]; i++; continue; }
			if (n == 't') { [out appendString:@"\t"]; i++; continue; }
			if (n == 'r') { [out appendString:@"\r"]; i++; continue; }
			if (n == '"' || n == '\\' || n == '\'') { [out appendFormat:@"%C", n]; i++; continue; }
		}
		[out appendFormat:@"%C", c];
	}
	return out;
}

- (NSArray<NSString *> *)localizedKeysInSource:(NSString *)text {
	NSMutableArray<NSString *> *keys = [NSMutableArray array];
	NSString *needle = @"NSLocalizedString(";
	NSUInteger idx = 0;
	while (idx < text.length) {
		NSRange found = [text rangeOfString:needle options:0 range:NSMakeRange(idx, text.length - idx)];
		if (found.location == NSNotFound) {
			break;
		}
		NSUInteger i = NSMaxRange(found);
		NSMutableString *joined = [NSMutableString string];
		BOOL sawLiteral = NO;
		while (i < text.length) {
			while (i < text.length && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[text characterAtIndex:i]]) {
				i++;
			}
			if (i >= text.length) {
				break;
			}
			BOOL objcLiteral = (i + 1 < text.length && [text characterAtIndex:i] == '@' && [text characterAtIndex:i + 1] == '"');
			BOOL cLiteral = sawLiteral && [text characterAtIndex:i] == '"';
			if (!objcLiteral && !cLiteral) {
				break;
			}
			i += objcLiteral ? 2 : 1;
			NSMutableString *buf = [NSMutableString string];
			while (i < text.length) {
				unichar c = [text characterAtIndex:i];
				if (c == '\\' && i + 1 < text.length) {
					[buf appendFormat:@"%C", c];
					[buf appendFormat:@"%C", [text characterAtIndex:i + 1]];
					i += 2;
					continue;
				}
				if (c == '"') {
					i++;
					break;
				}
				[buf appendFormat:@"%C", c];
				i++;
			}
			[joined appendString:[self objcUnescape:buf]];
			sawLiteral = YES;
		}
		if (joined.length > 0) {
			[keys addObject:joined];
		}
		idx = NSMaxRange(found);
	}
	return keys;
}

- (NSDictionary<NSString *, NSString *> *)catalogAtPath:(NSString *)path {
	NSError *error = nil;
	NSStringEncoding encoding = 0;
	NSString *text = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
	XCTAssertNil(error, @"Failed reading %@: %@", path, error);
	XCTAssertNotNil(text);

	NSMutableDictionary<NSString *, NSString *> *catalog = [NSMutableDictionary dictionary];
	NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^\"((?:\\\\.|[^\"\\\\])*)\"\\s*=\\s*\"((?:\\\\.|[^\"\\\\])*)\"\\s*;"
									       options:NSRegularExpressionAnchorsMatchLines
										 error:NULL];
	[re enumerateMatchesInString:text options:0 range:NSMakeRange(0, text.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		NSString *key = [self objcUnescape:[text substringWithRange:[result rangeAtIndex:1]]];
		NSString *value = [self objcUnescape:[text substringWithRange:[result rangeAtIndex:2]]];
		catalog[key] = value;
	}];
	return catalog;
}

- (NSUInteger)countOfToken:(NSString *)token inString:(NSString *)string {
	NSUInteger count = 0;
	NSRange search = NSMakeRange(0, string.length);
	while (search.location < string.length) {
		NSRange found = [string rangeOfString:token options:0 range:search];
		if (found.location == NSNotFound) {
			break;
		}
		count++;
		search.location = NSMaxRange(found);
		search.length = string.length - search.location;
	}
	return count;
}

- (BOOL)mustDifferFromEnglish:(NSString *)key {
	// Sentences and labels. Short tokens (On, Off, VPN, System) may match English.
	return key.length >= 12 && [key rangeOfString:@" "].location != NSNotFound;
}

- (void)testFocusPowerSettingsAndGatedStringsAreLocalized {
	NSMutableOrderedSet<NSString *> *keys = [NSMutableOrderedSet orderedSet];
	for (NSString *rel in [self sliceSourceFiles]) {
		NSString *path = [[self srcRoot] stringByAppendingPathComponent:rel];
		NSError *error = nil;
		NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
		XCTAssertNil(error, @"Failed reading %@", rel);
		for (NSString *key in [self localizedKeysInSource:text]) {
			[keys addObject:key];
		}
	}
	XCTAssertGreaterThan(keys.count, 40, @"Expected Focus/Power/Shortcut/gated keys from source");

	for (NSString *locale in [self shippingLocales]) {
		NSString *rel = [NSString stringWithFormat:@"Resources/%@.lproj/Localizable.strings", locale];
		NSString *path = [[self srcRoot] stringByAppendingPathComponent:rel];
		NSDictionary<NSString *, NSString *> *catalog = [self catalogAtPath:path];
		XCTAssertGreaterThan(catalog.count, 100, @"%@ catalog looks empty", locale);

		for (NSString *key in keys) {
			NSString *value = catalog[key];
			XCTAssertNotNil(value, @"%@ missing key: %@", locale, key);
			if (value == nil) {
				continue;
			}
			if (![locale isEqualToString:@"en"] && [self mustDifferFromEnglish:key]) {
				XCTAssertNotEqualObjects(value, key, @"%@ still English for: %@", locale, key);
			}
			for (NSString *token in @[ @"%@", @"%d" ]) {
				XCTAssertEqual([self countOfToken:token inString:key],
					       [self countOfToken:token inString:value],
					       @"%@ placeholder %@ mismatch for: %@", locale, token, key);
			}
		}
	}
}

@end
