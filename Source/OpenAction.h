//
//  OpenAction.h
//  ControlPlane
//
//  Created by David Symonds on 3/04/07.
//

#import "Action.h"


@interface OpenAction : Action <ActionWithFileParameter>

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithFile:(NSString *)file;

- (NSMutableDictionary *)dictionary;

- (NSString *)description;
- (BOOL)execute:(NSString **)errorString;

- (NSWorkspaceOpenConfiguration *)launchConfiguration;

@end
