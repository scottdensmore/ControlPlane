//
//  CPSystemInfo.h
//  ControlPlane
//
//  Created by Dustin Rue on 7/12/13.
//
//

#import <Foundation/Foundation.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <IOKit/IOKitLib.h>

@interface CPSystemInfo : NSObject

// returns hardware model string (MacBook7,1)
+ (NSString *) getHardwareModel;



// returns true if this is a portable Mac.  Currently a very simple test
// against whether or not the model name contains book in the name.  This should
// match MacBook, MacBookPro and MacBookAir.
+ (BOOL) isPortable;

+ (NSInteger) getOSVersion;

// Add this to your header file
+ (io_service_t) IOServicePortFromCGDisplayID:(CGDirectDisplayID) displayID;

@end
