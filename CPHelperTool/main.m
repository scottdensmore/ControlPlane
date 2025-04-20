//
//  main.m
//  CPHelperTool
//
//  Created by Scott Densmore on 3/29/25.
//

#import <Foundation/Foundation.h>
#import "CPHelperTool.h"

int main(int argc, const char * argv[]) {
    #pragma unused(argc)
    #pragma unused(argv)

    // We just create and start an instance of the main helper tool object and then
    // have it run the run loop forever.
    
    @autoreleasepool {
        CPHelperTool *helperTool;
        helperTool = [[CPHelperTool alloc] init];
        [helperTool run]; // This never comes back...
    }
    
    return EXIT_FAILURE; // ... so this should never be hit.
}
