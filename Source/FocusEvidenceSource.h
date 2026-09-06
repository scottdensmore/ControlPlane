//
//  FocusEvidenceSource.h
//  ControlPlane
//
//  Issue #113: Focus active/inactive via public Intents Focus Status API.
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "GenericEvidenceSource.h"

@interface FocusEvidenceSource : GenericEvidenceSource

- (id)init;
- (id)initForMatchingTests;
- (void)setFocusActiveForTesting:(BOOL)active;

- (void)start;
- (void)stop;

- (NSString *)name;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;
- (NSString *)getSuggestionLeadText:(NSString *)type;
- (NSArray *)getSuggestions;

@end
