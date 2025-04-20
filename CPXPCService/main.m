//
//  main.m
//  CPXPCService
//
//  Created by Scott Densmore on 3/29/25.
//

#import <Foundation/Foundation.h>
#import "CPXPCService.h"

int main(int argc, const char *argv[])
{
    #pragma unused(argc)
       #pragma unused(argv)

       // We just create and start an instance of the main XPC service object and then
       // have it resume the XPC service listener.

       @autoreleasepool {
           CPXPCService *service;

           service = [[CPXPCService alloc] init];
           assert(service != nil);
           
           [service run];                // This never comes back...
       }
       
       return EXIT_FAILURE;        // ... so this should never be hit.
}
