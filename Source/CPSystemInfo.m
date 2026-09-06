//
//  CPSystemInfo.m
//  ControlPlane
//
//  Created by Dustin Rue on 7/12/13.
//
//

#import "CPSystemInfo.h"
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation CPSystemInfo


+ (NSString *) getHardwareModel {
    static NSString *hwModel = nil;

    if (!hwModel) {
        size_t len = 0;
        if (!sysctlbyname("hw.model", NULL, &len, NULL, 0) && len) {
            char *model = malloc(len * sizeof(char));
            if (!sysctlbyname("hw.model", model, &len, NULL, 0)) {
                hwModel = [[NSString alloc] initWithUTF8String:model];
            }
            free(model);
        }
    }

    return hwModel;
}

+ (BOOL) isPortable {
    return ([[[CPSystemInfo getHardwareModel] lowercaseString] rangeOfString:@"book"].location != NSNotFound);
}

+ (NSInteger) getOSVersion {
    // get system version
    NSInteger major = 0, minor = 0;
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    major = version.majorVersion;
    minor = version.minorVersion;
    

    // get the version number into a format that
    // matches the availability macros (MAC_OS_X_VERSION_10_8)
    // This will probably break in 10.10 because 10.10 will become
    // 1100 which probably doesn't make sense
    return (major * 10 + minor) * 10;
}

+ (io_service_t) IOServicePortFromCGDisplayID:(CGDirectDisplayID) displayID {
    // #88: Harden against missing IODisplayConnect / incomplete info dictionaries
    // so callers (Monitor evidence, legacy brightness) never crash on lookup failure.
    if (displayID == kCGNullDirectDisplay)
        return 0;

    io_iterator_t iter = 0;
    io_service_t serv, servicePort = 0;

    CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
    if (!matching)
        return 0;

    // releases matching for us on success
    kern_return_t err = IOServiceGetMatchingServices(kIOMainPortDefault,
                                                     matching,
                                                     &iter);
    if (err) {
        // matching was not consumed on failure
        CFRelease(matching);
        return 0;
    }

    while ((serv = IOIteratorNext(iter)) != 0)
    {
        CFDictionaryRef info;
        CFIndex vendorID = 0, productID = 0, serialNumber = 0;
        CFNumberRef vendorIDRef, productIDRef;
        Boolean success;

        info = IODisplayCreateInfoDictionary(serv,
                                             kIODisplayOnlyPreferredName);
        if (!info) {
            IOObjectRelease(serv);
            continue;
        }

        vendorIDRef = CFDictionaryGetValue(info,
                                           CFSTR(kDisplayVendorID));
        productIDRef = CFDictionaryGetValue(info,
                                            CFSTR(kDisplayProductID));
        if (!vendorIDRef || !productIDRef) {
            CFRelease(info);
            IOObjectRelease(serv);
            continue;
        }

        success = CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType,
                                   &vendorID);
        success &= CFNumberGetValue(productIDRef, kCFNumberCFIndexType,
                                    &productID);

        const void *serialNumberPtr = NULL;
        if (CFDictionaryGetValueIfPresent(info, CFSTR(kDisplaySerialNumber), &serialNumberPtr) &&
            serialNumberPtr != NULL) {
            success &= CFNumberGetValue((CFNumberRef)serialNumberPtr, kCFNumberCFIndexType,
                                        &serialNumber);
        }

        if (!success ||
            CGDisplayVendorNumber(displayID) != vendorID  ||
            CGDisplayModelNumber(displayID) != productID  ||
            CGDisplaySerialNumber(displayID) != serialNumber)
        {
            CFRelease(info);
            IOObjectRelease(serv);
            continue;
        }

        // The VendorID, Product ID, and the Serial Number all Match Up!
        // Therefore we have found the appropriate display io_service
        servicePort = serv;
        CFRelease(info);
        break;
    }

    IOObjectRelease(iter);
    return servicePort;
}


@end
