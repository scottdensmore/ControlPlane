//
//  MonitorEvidenceSource.h
//  ControlPlane
//
//  Created by David Symonds on 2/07/07.
//

#import "GenericLoopingEvidenceSource.h"


@interface MonitorEvidenceSource : GenericLoopingEvidenceSource {
	NSLock *lock;
	NSMutableArray *monitors;
	NSInteger totalDisplayCount;
	NSInteger externalDisplayCount;
	NSString *arrangementFingerprint;
}

- (id)init;
- (id)initForMatchingTests;
- (void)dealloc;

- (void)doUpdate;
- (void)clearCollectedData;

- (NSString *)name;
- (NSArray *)typesOfRulesMatched;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;
- (NSString *)getSuggestionLeadText:(NSString *)type;
- (NSArray *)getSuggestions;

+ (NSString *)arrangementFingerprintForDisplayDescriptors:(NSArray *)descriptors;
+ (BOOL)displayCountParameter:(NSString *)parameter
                 matchesTotal:(NSInteger)total
                     external:(NSInteger)external;

- (void)setDisplayDescriptorsForTesting:(NSArray *)descriptors;
- (void)setMonitorsForTesting:(NSArray *)monitorRecords;

@end
