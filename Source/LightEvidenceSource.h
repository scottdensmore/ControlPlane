//
//  LightEvidenceSource.h
//  ControlPlane
//
//  Created by Rodrigo Damazio on 09/07/07.
//  Some optimizations and refactoring by Vladimir Beloborodov (VladimirTechMan) on 05 August 2013.
//

#import "LoopingEvidenceSource.h"

@interface LightEvidenceSource : LoopingEvidenceSource

- (id)init;
- (id)initForUnavailableLMUTesting;
- (void)dealloc;

- (void)doUpdate;
- (void)clearCollectedData;

- (NSMutableDictionary *)readFromPanel;
- (void)writeToPanel:(NSDictionary *)dict usingType:(NSString *)type;

- (NSString *)name;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;

/// YES when IOKit reports an AppleLMUController (ambient light / keyboard backlight).
/// Commonly absent on Apple silicon and many modern Macs.
+ (BOOL)isAppleLMUControllerAvailable;

/// Localized label shown in the rule sheet when the LMU is absent.
+ (NSString *)unavailableLevelDisplayString;

@end
