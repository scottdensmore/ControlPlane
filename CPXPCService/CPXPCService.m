//
//  CPXPCService.m
//  CPXPCService
//
//  Created by Scott Densmore on 3/29/25.
//

#import "CPXPCService.h"
#import "CPAuthorization.h"
#import "CPHelperToolProtocol.h"
#import "../Common/CPCommonConstants.h"

#include <ServiceManagement/ServiceManagement.h>

@interface CPXPCService () <NSXPCListenerDelegate, CPXPCServiceProtocol>

@property (atomic, strong, readonly ) NSXPCListener *    listener;
@property (atomic, copy,   readonly ) NSData *           authorization;
@property (atomic, strong, readonly ) NSOperationQueue * queue;

@property (atomic, strong, readwrite) NSXPCConnection *  helperToolConnection;      // only accessed or modified by operations on self.queue

@end

@implementation CPXPCService {
    AuthorizationRef    _authRef;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        OSStatus                    err;
        AuthorizationExternalForm   extForm;
        
        self->_listener = [NSXPCListener serviceListener];
        assert(self->_listener != nil);     // this code must be run from an XPC service

        self->_listener.delegate = self;

        err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
        if (err == errAuthorizationSuccess) {
            err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
        }
        if (err == errAuthorizationSuccess) {
            self->_authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
        }
        assert(err == errAuthorizationSuccess);
        
        self->_queue = [[NSOperationQueue alloc] init];
        [self->_queue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (void)dealloc
{
    if (self->_authRef != NULL) {
        (void) AuthorizationFree(self->_authRef, 0);
    }
}

- (void)run
{
    [self.listener resume];     // never comes back
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    assert(listener == self.listener);
    assert(newConnection != nil);

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CPXPCServiceProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

#pragma mark - CPXPCServiceProtocol

- (void)installHelperToolWithReply:(void(^)(NSError * error))reply
{
    Boolean             success;
    CFErrorRef          error;
    
    success = SMJobBless(
        kSMDomainSystemLaunchd,
        (CFStringRef)kHelperToolMachServiceName,
        self->_authRef,
        &error
    );

    if (success) {
        reply(nil);
    } else {
        assert(error != NULL);
        reply((__bridge NSError *) error);
        CFRelease(error);
    }
}

- (void)setupAuthorizationRights
{
    [CPAuthorization setupAuthorizationRights:self->_authRef];
}

- (void)connectWithEndpointAndAuthorizationReply:(void(^)(NSXPCListenerEndpoint * endpoint, NSData * authorization))reply
    // Part of XPCServiceProtocol.  Called by the app to get an endpoint that's
    // connected to the helper tool.  This a also returns the XPC service's authorization
    // reference so that the app can pass that to the requests it sends to the helper tool.
    // Without this authorization will fail because the app is sandboxed.
{
    // Because we access helperToolConnection, we have to run on the operation queue.
    
    [self.queue addOperationWithBlock:^{

        // Create our connection to the helper tool if it's not already in place.
        
        if (self.helperToolConnection == nil) {
            self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
            self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CPHelperToolProtocol)];
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-retain-cycles"
            // We can ignore the retain cycle warning because a) the retain taken by the
            // invalidation handler block is released by us setting it to nil when the block
            // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
            // will be released when that operation completes and the operation itself is deallocated
            // (notably self does not have a reference to the NSBlockOperation).
            self.helperToolConnection.invalidationHandler = ^{
                // If the connection gets invalidated then, on our operation queue thread, nil out our
                // reference to it.  This ensures that we attempt to rebuild it the next time around.
                self.helperToolConnection.invalidationHandler = nil;
                [self.queue addOperationWithBlock:^{
                    self.helperToolConnection = nil;
                    NSLog(@"connection invalidated");
                }];
            };
            #pragma clang diagnostic pop
            [self.helperToolConnection resume];
        }

        // Call the helper tool to get the endpoint we need.
        
        [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
            NSLog(@"connect failed: %@ / %d", [proxyError domain], (int) [proxyError code]);
            reply(nil, nil);
        }] connectWithEndpointReply:^(NSXPCListenerEndpoint *replyEndpoint) {
            reply(replyEndpoint, self.authorization);
        }];
    }];
}


@end
