//
//  SparkleEDKeyTests.m
//  ControlPlaneTests
//
//  Issue #114: document that SUPublicEDKey must be present before shipping updates.
//

#import <XCTest/XCTest.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface SparkleEDKeyTests : XCTestCase
@end

@implementation SparkleEDKeyTests

- (NSString *)srcRoot {
	NSString *root = @CONTROLPLANE_SRCROOT;
	XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set");
	return root;
}

- (void)testInfoPlistDocumentsMissingSUPublicEDKeyOrHasRealKey {
	NSString *path = [[self srcRoot] stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
	XCTAssertNotNil(plist);
	NSString *key = plist[@"SUPublicEDKey"];
	if (key.length > 0) {
		// Real EdDSA public keys from Sparkle generate_keys are base64 and non-placeholder.
		XCTAssertFalse([key containsString:@"PASTE"]);
		XCTAssertFalse([key containsString:@"REPLACE"]);
		XCTAssertGreaterThan(key.length, 20u);
		return;
	}

	// Key generation requires interactive Keychain access on a maintainer Mac.
	// Until then, shipping signed Sparkle updates is forbidden (see docs/releasing.md).
	NSString *releasing =
	    [[self srcRoot] stringByAppendingPathComponent:@"docs/releasing.md"];
	NSError *error = nil;
	NSString *docs = [NSString stringWithContentsOfFile:releasing
						   encoding:NSUTF8StringEncoding
						      error:&error];
	XCTAssertNil(error);
	XCTAssertTrue([docs containsString:@"SUPublicEDKey"],
		      @"releasing.md must document SUPublicEDKey");
	XCTAssertTrue([docs rangeOfString:@"FORBID" options:NSCaseInsensitiveSearch].location != NSNotFound
			  || [docs rangeOfString:@"must not ship" options:NSCaseInsensitiveSearch].location != NSNotFound
			  || [docs rangeOfString:@"Do not publish" options:NSCaseInsensitiveSearch].location != NSNotFound,
		      @"releasing.md must forbid shipping without SUPublicEDKey");
}

- (void)testReleasingHasEdDSAMaintainerChecklist {
	NSString *releasing =
	    [[self srcRoot] stringByAppendingPathComponent:@"docs/releasing.md"];
	NSError *error = nil;
	NSString *docs = [NSString stringWithContentsOfFile:releasing
						   encoding:NSUTF8StringEncoding
						      error:&error];
	XCTAssertNil(error);
	XCTAssertTrue([docs containsString:@"generate_keys"]);
	XCTAssertTrue([docs containsString:@"sign_update"] || [docs containsString:@"sparkle_sign_archive"]);
	XCTAssertTrue([docs containsString:@"Keychain"]);
	XCTAssertTrue([docs containsString:@"private key"] || [docs containsString:@"Private key"]);
}

@end
