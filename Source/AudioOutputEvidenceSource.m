//
//  AudioOutputEvidenceSource.m
//  ControlPlane
//
//  Created by David Symonds on 11/07/07.
//  Updated by Dustin Rue 9/7/2012
//  Hardened for public CoreAudio transport/UID matching (issue #123).
//

#import "AudioOutputEvidenceSource.h"
#import "DSLogger.h"
#import <CoreAudio/CoreAudio.h>


static OSStatus sourceChange(AudioObjectID inDevice, UInt32 inChannel,
			     const AudioObjectPropertyAddress *inPropertyID, void *inClientData)
{
	AudioOutputEvidenceSource *src = (__bridge AudioOutputEvidenceSource *) inClientData;

	@autoreleasepool {
		[src doRealUpdate];
	}

	return 0;
}

static BOOL CPAudioReadUInt32Property(AudioObjectID object,
				      AudioObjectPropertySelector selector,
				      AudioObjectPropertyScope scope,
				      UInt32 *outValue)
{
	if (!outValue)
		return NO;

	UInt32 size = sizeof(UInt32);
	AudioObjectPropertyAddress address = {
		selector,
		scope,
		kAudioObjectPropertyElementMain
	};

	return AudioObjectGetPropertyData(object, &address, 0, NULL, &size, outValue) == noErr;
}

static NSString *CPAudioDeviceUID(AudioDeviceID device)
{
	AudioObjectPropertyAddress address = {
		kAudioDevicePropertyDeviceUID,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMain
	};
	CFStringRef uid = NULL;
	UInt32 size = sizeof(uid);
	if (AudioObjectGetPropertyData(device, &address, 0, NULL, &size, &uid) != noErr || !uid)
		return nil;
	return (__bridge_transfer NSString *)uid;
}

static BOOL CPAudioDeviceSupportsOutputDataSource(AudioDeviceID device)
{
	AudioObjectPropertyAddress address = {
		kAudioDevicePropertyDataSource,
		kAudioDevicePropertyScopeOutput,
		kAudioObjectPropertyElementMain
	};
	return AudioObjectHasProperty(device, &address);
}

static AudioDeviceID CPAudioFindBuiltInOutputDevice(void)
{
	AudioObjectPropertyAddress devicesAddress = {
		kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMain
	};

	UInt32 propertySize = 0;
	if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &devicesAddress, 0, NULL, &propertySize) != noErr)
		return 0;

	UInt32 deviceCount = propertySize / sizeof(AudioDeviceID);
	if (deviceCount == 0)
		return 0;

	AudioDeviceID *audioDevices = (AudioDeviceID *)malloc(propertySize);
	if (!audioDevices)
		return 0;

	AudioDeviceID found = 0;
	if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &devicesAddress, 0, NULL, &propertySize, audioDevices) == noErr) {
		for (UInt32 i = 0; i < deviceCount; i++) {
			UInt32 transport = kAudioDeviceTransportTypeUnknown;
			if (!CPAudioReadUInt32Property(audioDevices[i],
						       kAudioDevicePropertyTransportType,
						       kAudioObjectPropertyScopeGlobal,
						       &transport))
				continue;
			if (transport != kAudioDeviceTransportTypeBuiltIn)
				continue;
			if (!CPAudioDeviceSupportsOutputDataSource(audioDevices[i]))
				continue;

			found = audioDevices[i];
			break;
		}
	}

	free(audioDevices);
	return found;
}

@implementation AudioOutputEvidenceSource

- (id)init
{
	if (!(self = [super init]))
		return nil;

	source = 0;
	deviceID = 0;
	builtinDeviceID = 0;
	return self;
}

- (id)initForMatchingTests
{
	if (!(self = [super initForMatchingTests]))
		return nil;

	source = 0;
	deviceID = 0;
	builtinDeviceID = 0;
	return self;
}

- (void)setOutputIdentityForTestingWithTransportType:(UInt32)transportType
                                          dataSource:(UInt32)dataSource
{
	source = [[self class] ruleParameterForTransportType:transportType dataSource:dataSource];
	[self setDataCollected:YES];
}

+ (UInt32)ruleParameterForTransportType:(UInt32)transportType
                             dataSource:(UInt32)dataSource
{
	if (transportType == kAudioDeviceTransportTypeBuiltIn) {
		if (dataSource == kCPAudioOutputSourceHeadphones ||
		    dataSource == kCPAudioOutputSourceInternalSpeakers ||
		    dataSource == kCPAudioOutputSourceExternalSpeakers) {
			return dataSource;
		}
		// Built-in with missing/unknown data source: prefer internal speakers over external.
		return kCPAudioOutputSourceInternalSpeakers;
	}

	// USB / Bluetooth / HDMI / AirPlay / etc. → external speakers rule.
	return kCPAudioOutputSourceExternalSpeakers;
}

- (NSString *)description
{
	return NSLocalizedString(@"Create rules based on what audio output device is currently in use.", @"");
}

- (void)doRealUpdate
{
	UInt32 sz = sizeof(deviceID);
	AudioObjectPropertyAddress defaultAddress = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMain
	};

	if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &defaultAddress, 0, NULL, &sz, &deviceID) != noErr) {
		DSLogEvidence(@"AudioOutput: failed to read default output device");
		return;
	}

	UInt32 transport = kAudioDeviceTransportTypeUnknown;
	if (!CPAudioReadUInt32Property(deviceID,
				       kAudioDevicePropertyTransportType,
				       kAudioObjectPropertyScopeGlobal,
				       &transport)) {
		transport = kAudioDeviceTransportTypeUnknown;
	}

	NSString *uid = CPAudioDeviceUID(deviceID);
	BOOL isBuiltInOutput = (builtinDeviceID != 0 && deviceID == builtinDeviceID) ||
		(transport == kAudioDeviceTransportTypeBuiltIn);

	UInt32 dataSource = 0;
	if (isBuiltInOutput) {
		AudioDeviceID probeID = (builtinDeviceID != 0) ? builtinDeviceID : deviceID;
		if (!CPAudioReadUInt32Property(probeID,
					       kAudioDevicePropertyDataSource,
					       kAudioDevicePropertyScopeOutput,
					       &dataSource)) {
			dataSource = 0;
		}
		// Ensure classifier treats this as built-in even if transport read failed.
		transport = kAudioDeviceTransportTypeBuiltIn;
	}

	UInt32 previous = source;
	source = [[self class] ruleParameterForTransportType:transport dataSource:dataSource];
	[self setDataCollected:YES];

	if (previous != source) {
		DSLogEvidence(@"AudioOutput identity uid=%@ transport=0x%08x dataSource=0x%08x rule=0x%08x",
			      uid ?: @"(none)",
			      (unsigned int)transport,
			      (unsigned int)dataSource,
			      (unsigned int)source);
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"evidenceSourceDataDidChange" object:nil];
}

- (NSString *)name
{
	return @"AudioOutput";
}

- (BOOL)doesRuleMatch:(NSDictionary *)rule
{
	return (((UInt32) [[rule objectForKey:@"parameter"] intValue]) == source);
}

- (NSString *)getSuggestionLeadText:(NSString *)type
{
	return NSLocalizedString(@"Audio output going to", @"In rule-adding dialog");
}

- (NSArray *)getSuggestions
{
	return [NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"AudioOutput", @"type",
			[NSNumber numberWithInt:kCPAudioOutputSourceInternalSpeakers], @"parameter",
			NSLocalizedString(@"Internal speakers", @""), @"description", nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"AudioOutput", @"type",
			[NSNumber numberWithInt:kCPAudioOutputSourceHeadphones], @"parameter",
			NSLocalizedString(@"Headphones", @""), @"description", nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"AudioOutput", @"type",
			[NSNumber numberWithInt:kCPAudioOutputSourceExternalSpeakers], @"parameter",
			NSLocalizedString(@"External speakers", @""), @"description", nil],
		nil];
}

- (void)start
{
	if (running)
		return;

	UInt32 sz = sizeof(deviceID);
	AudioObjectPropertyAddress address = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMain
	};

	if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &sz, &deviceID) != noErr) {
		DSLogEvidence(@"AudioOutput: failed to read default output device at start");
		return;
	}

	if (AudioObjectAddPropertyListener(kAudioObjectSystemObject, &address, &sourceChange, (__bridge void *)self) != noErr) {
		DSLogEvidence(@"AudioOutput: failed to listen for default output device changes");
		return;
	}

	builtinDeviceID = CPAudioFindBuiltInOutputDevice();
	if (builtinDeviceID != 0) {
		AudioObjectPropertyAddress sourceAddr = {
			kAudioDevicePropertyDataSource,
			kAudioDevicePropertyScopeOutput,
			kAudioObjectPropertyElementMain
		};
		if (AudioObjectAddPropertyListener(builtinDeviceID, &sourceAddr, &sourceChange, (__bridge void *)self) != noErr) {
			DSLogEvidence(@"AudioOutput: failed to listen for built-in data source changes");
			// Still usable via default-device changes (USB/BT/etc.).
		}
	} else {
		DSLogEvidence(@"AudioOutput: no built-in output device found via transport type; external-only matching");
	}

	[self doRealUpdate];
	running = YES;
}

- (void)stop
{
	if (!running)
		return;

	AudioObjectPropertyAddress address = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMain
	};

	AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &address, &sourceChange, (__bridge void *)self);

	if (builtinDeviceID != 0) {
		address.mSelector = kAudioDevicePropertyDataSource;
		address.mScope = kAudioDevicePropertyScopeOutput;
		address.mElement = kAudioObjectPropertyElementMain;
		AudioObjectRemovePropertyListener(builtinDeviceID, &address, &sourceChange, (__bridge void *)self);
	}

	source = 0;
	builtinDeviceID = 0;
	[self setDataCollected:NO];
	running = NO;
}

- (NSString *)friendlyName
{
	return NSLocalizedString(@"Audio Output", @"");
}

@end
