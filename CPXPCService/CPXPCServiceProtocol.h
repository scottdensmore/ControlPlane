//
//  CPXPCServiceProtocol.h
//  CPXPCService
//
//  Created by Scott Densmore on 3/29/25.
//

#import <Foundation/Foundation.h>

@protocol CPXPCServiceProtocol

@required

// Called by the app to install the helper tool.
- (void)installHelperToolWithReply:(void(^)(NSError * error))reply;
    
// Called by the app at startup time to set up our authorization rights in the
// authorization database.
- (void)setupAuthorizationRights;
    
// Called by the app to get an endpoint that's connected to the helper tool.
// This a also returns the XPC service's authorization reference so that
// the app can pass that to the requests it sends to the helper tool.
// Without this authorization will fail because the app is sandboxed.
- (void)connectWithEndpointAndAuthorizationReply:(void(^)(NSXPCListenerEndpoint * endpoint, NSData * authorization))reply;
    
@end

