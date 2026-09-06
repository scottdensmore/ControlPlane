//
//  SparkleVendoredArchitectureTests.m
//  ControlPlaneTests
//

#import <XCTest/XCTest.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <fcntl.h>
#include <unistd.h>

#ifndef CONTROLPLANE_SRCROOT
#define CONTROLPLANE_SRCROOT ""
#endif

@interface SparkleVendoredArchitectureTests : XCTestCase
@end

@implementation SparkleVendoredArchitectureTests

static BOOL CPBinaryIncludesArchitecture(NSString *binaryPath, cpu_type_t cpuType) {
    int fd = open(binaryPath.fileSystemRepresentation, O_RDONLY);
    if (fd < 0) {
        return NO;
    }

    BOOL found = NO;
    struct mach_header header = {0};
    if (read(fd, &header, sizeof(header)) == (ssize_t)sizeof(header)) {
        if (header.magic == MH_MAGIC_64 || header.magic == MH_CIGAM_64) {
            found = (header.cputype == cpuType);
        } else if (header.magic == FAT_MAGIC || header.magic == FAT_CIGAM) {
            lseek(fd, 0, SEEK_SET);
            struct fat_header fatHeader = {0};
            if (read(fd, &fatHeader, sizeof(fatHeader)) == (ssize_t)sizeof(fatHeader)) {
                uint32_t nfat_arch = OSSwapBigToHostInt32(fatHeader.nfat_arch);
                for (uint32_t i = 0; i < nfat_arch; i++) {
                    struct fat_arch arch = {0};
                    if (read(fd, &arch, sizeof(arch)) != (ssize_t)sizeof(arch)) {
                        break;
                    }
                    if (OSSwapBigToHostInt32(arch.cputype) == (uint32_t)cpuType) {
                        found = YES;
                        break;
                    }
                }
            }
        }
    }

    close(fd);
    return found;
}

- (NSString *)vendoredSparkleFrameworkRoot {
    NSString *root = @CONTROLPLANE_SRCROOT;
    XCTAssertTrue(root.length > 0, @"CONTROLPLANE_SRCROOT must be set for Sparkle arch tests");
    return [root stringByAppendingPathComponent:@"Frameworks/Sparkle.framework"];
}

- (NSString *)vendoredSparkleBinaryPath {
    return [[self vendoredSparkleFrameworkRoot]
            stringByAppendingPathComponent:@"Versions/Current/Sparkle"];
}

- (NSDictionary *)vendoredSparkleInfoDictionary {
    NSString *infoPath = [[self vendoredSparkleFrameworkRoot]
                          stringByAppendingPathComponent:@"Versions/Current/Resources/Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
    XCTAssertNotNil(info, @"Expected Sparkle Info.plist at %@", infoPath);
    return info;
}

- (void)testVendoredSparkleIncludesArm64 {
    NSString *sparkleBinary = [self vendoredSparkleBinaryPath];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:sparkleBinary],
                  @"Expected vendored Sparkle at %@", sparkleBinary);
    XCTAssertTrue(CPBinaryIncludesArchitecture(sparkleBinary, CPU_TYPE_ARM64),
                  @"Vendored Sparkle must include arm64 for native Apple Silicon builds");
}

- (void)testVendoredSparkleIncludesX86_64 {
    NSString *sparkleBinary = [self vendoredSparkleBinaryPath];
    XCTAssertTrue(CPBinaryIncludesArchitecture(sparkleBinary, CPU_TYPE_X86_64),
                  @"Vendored Sparkle must include x86_64 for Intel Macs");
}

- (void)testVendoredSparkleIsVersion2 {
    NSDictionary *info = [self vendoredSparkleInfoDictionary];
    NSString *shortVersion = info[@"CFBundleShortVersionString"];
    XCTAssertTrue([shortVersion hasPrefix:@"2."],
                  @"Expected Sparkle 2.x, got %@", shortVersion);
}

- (void)testInfoPlistUsesEdDSANotDSA {
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *plistPath = [root stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    XCTAssertNotNil(info, @"Expected Info.plist at %@", plistPath);
    XCTAssertNil(info[@"SUPublicDSAKeyFile"],
                 @"DSA public key file must not be required for Sparkle 2 releases");
    XCTAssertNotNil(info[@"SUFeedURL"], @"SUFeedURL should remain configured");
}

@end
