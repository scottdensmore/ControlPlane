//
//  CPXPCService.h
//  CPXPCService
//
//  Created by Scott Densmore on 3/29/25.
//

#import <Foundation/Foundation.h>
#import "CPXPCServiceProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface CPXPCService : NSObject

- (id)init;

- (void)run;

@end
