//
//  AudioOutputRuleMatchTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#import <CoreAudio/CoreAudio.h>
#import "AudioOutputEvidenceSource.h"

@interface AudioOutputRuleMatchTests : XCTestCase
@end

@implementation AudioOutputRuleMatchTests

- (void)testBuiltInHeadphonesMatchesHeadphonesRule
{
	AudioOutputEvidenceSource *source = [[AudioOutputEvidenceSource alloc] initForMatchingTests];
	[source setOutputIdentityForTestingWithTransportType:kAudioDeviceTransportTypeBuiltIn
	                                          dataSource:kCPAudioOutputSourceHeadphones];
	NSDictionary *headphones = @{ @"parameter": @(kCPAudioOutputSourceHeadphones) };
	NSDictionary *speakers = @{ @"parameter": @(kCPAudioOutputSourceInternalSpeakers) };
	XCTAssertTrue([source doesRuleMatch:headphones]);
	XCTAssertFalse([source doesRuleMatch:speakers]);
}

- (void)testBuiltInSpeakersMatchesInternalSpeakerRule
{
	AudioOutputEvidenceSource *source = [[AudioOutputEvidenceSource alloc] initForMatchingTests];
	[source setOutputIdentityForTestingWithTransportType:kAudioDeviceTransportTypeBuiltIn
	                                          dataSource:kCPAudioOutputSourceInternalSpeakers];
	NSDictionary *speakers = @{ @"parameter": @(kCPAudioOutputSourceInternalSpeakers) };
	NSDictionary *headphones = @{ @"parameter": @(kCPAudioOutputSourceHeadphones) };
	XCTAssertTrue([source doesRuleMatch:speakers]);
	XCTAssertFalse([source doesRuleMatch:headphones]);
}

- (void)testBluetoothTransportMapsToExternalSpeakers
{
	AudioOutputEvidenceSource *source = [[AudioOutputEvidenceSource alloc] initForMatchingTests];
	[source setOutputIdentityForTestingWithTransportType:kAudioDeviceTransportTypeBluetooth
	                                          dataSource:0];
	NSDictionary *external = @{ @"parameter": @(kCPAudioOutputSourceExternalSpeakers) };
	NSDictionary *headphones = @{ @"parameter": @(kCPAudioOutputSourceHeadphones) };
	XCTAssertTrue([source doesRuleMatch:external]);
	XCTAssertFalse([source doesRuleMatch:headphones]);
}

- (void)testUSBTransportMapsToExternalSpeakers
{
	UInt32 param = [AudioOutputEvidenceSource ruleParameterForTransportType:kAudioDeviceTransportTypeUSB
	                                                             dataSource:kCPAudioOutputSourceHeadphones];
	XCTAssertEqual(param, (UInt32)kCPAudioOutputSourceExternalSpeakers);
}

- (void)testClassifierDistinguishesHeadphonesAndSpeakersOnBuiltIn
{
	UInt32 headphones = [AudioOutputEvidenceSource ruleParameterForTransportType:kAudioDeviceTransportTypeBuiltIn
	                                                                  dataSource:kCPAudioOutputSourceHeadphones];
	UInt32 speakers = [AudioOutputEvidenceSource ruleParameterForTransportType:kAudioDeviceTransportTypeBuiltIn
	                                                                dataSource:kCPAudioOutputSourceInternalSpeakers];
	XCTAssertEqual(headphones, (UInt32)kCPAudioOutputSourceHeadphones);
	XCTAssertEqual(speakers, (UInt32)kCPAudioOutputSourceInternalSpeakers);
	XCTAssertNotEqual(headphones, speakers);
}

@end
