//
//  CPHelperCommandRunner.h
//  com.scottdensmore.CPHelperTool
//
//  Argv-array process runner for privileged helper commands (#86).
//  No shell. No sprintf into system().
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Fixed absolute paths used by the helper (never from XPC clients).
FOUNDATION_EXPORT NSString * const kCPHelperPathTmutil;
FOUNDATION_EXPORT NSString * const kCPHelperPathPmset;
FOUNDATION_EXPORT NSString * const kCPHelperPathCupsctl;
FOUNDATION_EXPORT NSString * const kCPHelperPathLaunchctl;
FOUNDATION_EXPORT NSString * const kCPHelperPathSystemsetup;
FOUNDATION_EXPORT NSString * const kCPHelperPathSocketFilterFW;
FOUNDATION_EXPORT NSString * const kCPHelperPathSMBSyncPreferences;
FOUNDATION_EXPORT NSString * const kCPHelperPathSMBDPlist;
FOUNDATION_EXPORT NSString * const kCPHelperPathSSHPlist;

@interface CPHelperCommandRunner : NSObject

/// Runs `path` with `arguments` via posix_spawn (no shell). Returns process exit status, or a positive errno-style code on spawn failure.
+ (int)runExecutable:(NSString *)path arguments:(nullable NSArray<NSString *> *)arguments;

/// Display sleep minutes from XPC: 0 disables; reject negatives and absurdly large values.
+ (BOOL)isValidDisplaySleepMinutes:(NSInteger)minutes;

+ (NSArray<NSString *> *)argumentsForTmutilEnable;
+ (NSArray<NSString *> *)argumentsForTmutilDisable;
+ (NSArray<NSString *> *)argumentsForTmutilStartBackup;
+ (NSArray<NSString *> *)argumentsForTmutilStopBackup;

+ (NSArray<NSString *> *)argumentsForFirewallEnable;
+ (NSArray<NSString *> *)argumentsForFirewallDisable;

+ (NSArray<NSString *> *)argumentsForDisplaySleepMinutes:(NSInteger)minutes;

+ (NSArray<NSString *> *)argumentsForPrinterSharingEnable;
+ (NSArray<NSString *> *)argumentsForPrinterSharingDisable;

+ (NSArray<NSString *> *)argumentsForSMBEnable;
+ (NSArray<NSString *> *)argumentsForSMBDisable;

+ (NSArray<NSString *> *)argumentsForRemoteLoginEnable;
+ (NSArray<NSString *> *)argumentsForRemoteLoginDisable;

@end

NS_ASSUME_NONNULL_END
