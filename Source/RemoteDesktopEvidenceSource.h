//
//  RemoteDesktopEvidenceSource.h
//  ControlPlane
//
//  Created by Dustin Rue on 4/19/15.
//
//

#import "GenericEvidenceSource.h"

@interface RemoteDesktopEvidenceSource : GenericEvidenceSource
@property BOOL userConnected;
/// YES after a real (or injected) com.apple.remotedesktop.viewerNames update.
@property (nonatomic, assign, readonly) BOOL receivedRemoteDesktopNotify;

- (id)init;
- (id)initForMatchingTests;
- (void)setUserConnectedForTesting:(BOOL)connected;
- (void)applyViewerNamesNotificationUserInfoForTesting:(NSDictionary *)userInfo;

- (void)start;
- (void)stop;

- (NSString *)name;
- (BOOL)doesRuleMatch:(NSDictionary *)rule;
- (NSString *)getSuggestionLeadText:(NSString *)type;
- (NSArray *)getSuggestions;
@end
