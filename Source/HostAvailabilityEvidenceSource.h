//
//  HostAvailabilityEvidenceSource.h
//  ControlPlane
//
//  Created by Dustin Rue on 8/1/13.
//

#import "EvidenceSource.h"

@interface HostAvailabilityEvidenceSource : EvidenceSource

@property (atomic, strong) NSMutableDictionary *monitoredHosts;
@property (assign) IBOutlet NSComboBox *hostOrIp;

- (id)initForMatchingTests;
- (void)setHost:(NSString *)host available:(BOOL)available;

@end
