//
//  AudioOutputEvidenceSource.h
//  ControlPlane
//
//  Created by David Symonds on 11/07/07.
//

#import "GenericEvidenceSource.h"
#import <CoreAudio/CoreAudio.h>

/// Rule-parameter FourCCs historically stored in user rules (same values as legacy IOAudio port subtypes).
enum {
	kCPAudioOutputSourceInternalSpeakers = 'ispk',
	kCPAudioOutputSourceHeadphones = 'hdpn',
	kCPAudioOutputSourceExternalSpeakers = 'espk',
};

@interface AudioOutputEvidenceSource : GenericEvidenceSource {
	AudioDeviceID deviceID;
	AudioDeviceID builtinDeviceID;
	UInt32 source;
}

- (id)init;

- (id)initForMatchingTests;
/// Injects a public CoreAudio-style identity (transport + data source) for unit tests.
- (void)setOutputIdentityForTestingWithTransportType:(UInt32)transportType
                                          dataSource:(UInt32)dataSource;

/// Maps public CoreAudio transport + optional built-in data source to a stable rule parameter.
+ (UInt32)ruleParameterForTransportType:(UInt32)transportType
                             dataSource:(UInt32)dataSource;

- (void)doRealUpdate;

- (void)start;
- (void)stop;

- (NSString *)name;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;
- (NSString *)getSuggestionLeadText:(NSString *)type;
- (NSArray *)getSuggestions;

@end
