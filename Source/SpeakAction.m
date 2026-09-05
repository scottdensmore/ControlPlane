//
//    SpeakAction.m
//    ControlPlane
//
//    Created by David Jennes on 02/09/11.
//    Copyright 2011. All rights reserved.
//
//  Minor improvements by Vladimir Beloborodov (VladimirTechMan) on 21 July 2013.
//  Updated to use AVSpeechSynthesizer by Scott Densmore on 01 September 2023.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "SpeakAction.h"
#import <AVFoundation/AVFoundation.h>

@interface SpeakAction () <AVSpeechSynthesizerDelegate> {
    NSString *text;
}

@property (strong, atomic, readwrite) AVSpeechSynthesizer *synth;

@end

@implementation SpeakAction

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    text = [[NSString alloc] init];
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super initWithDictionary: dict];
    if (!self) {
        return nil;
    }

    text = [dict[@"parameter"] copy];

    return self;
}

- (NSMutableDictionary *)dictionary {
    NSMutableDictionary *dict = [super dictionary];
    dict[@"parameter"] = [text copy];
    return dict;
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedString(@"Speak text '%@'.", @""), text];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.synth = nil;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.synth = nil;
}

- (BOOL)execute:(NSString **)errorString {
    AVSpeechSynthesizer *synth = self.synth;
    if (!synth) {
        self.synth = synth = [[AVSpeechSynthesizer alloc] init];
        [synth setDelegate:self];
    }
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:[[NSLocale currentLocale] languageCode]];
    
    [synth speakUtterance:utterance];
    
    // Since AVSpeechSynthesizer doesn't have a direct way to check success like NSSpeechSynthesizer,
    // we'll assume it succeeded unless there's an obvious problem
    if (!text || [text length] == 0) {
        *errorString = NSLocalizedString(@"Cannot speak empty text.", @"");
        self.synth = nil;
        return NO;
    }
    
    return YES;
}

+ (NSString *)helpText {
    return NSLocalizedString(@"The parameter for the Speak action is the text to be spoken.", @"");
}

+ (NSString *)creationHelpText {
    return NSLocalizedString(@"Speak text:", @"");
}

+ (NSString *)friendlyName {
    return NSLocalizedString(@"Speak Phrase", @"");
}

+ (NSString *)menuCategory {
    return NSLocalizedString(@"Misc", @"");
}

@end
