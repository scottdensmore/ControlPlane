//
//  CPHelperCommandRunner.m
//  com.scottdensmore.CPHelperTool
//
//  Argv-array process runner for privileged helper commands (#86).
//

#import "CPHelperCommandRunner.h"

#include <errno.h>
#include <spawn.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <string.h>

extern char **environ;

NSString * const kCPHelperPathTmutil = @"/usr/bin/tmutil";
NSString * const kCPHelperPathPmset = @"/usr/bin/pmset";
NSString * const kCPHelperPathCupsctl = @"/usr/sbin/cupsctl";
NSString * const kCPHelperPathLaunchctl = @"/bin/launchctl";
NSString * const kCPHelperPathSystemsetup = @"/usr/sbin/systemsetup";
NSString * const kCPHelperPathSocketFilterFW = @"/usr/libexec/ApplicationFirewall/socketfilterfw";
NSString * const kCPHelperPathSMBSyncPreferences = @"/usr/libexec/smb-sync-preferences";
NSString * const kCPHelperPathSMBDPlist = @"/System/Library/LaunchDaemons/com.apple.smbd.plist";
NSString * const kCPHelperPathSSHPlist = @"/System/Library/LaunchDaemons/ssh.plist";

@implementation CPHelperCommandRunner

+ (BOOL)isValidDisplaySleepMinutes:(NSInteger)minutes
{
    // 0 = Never; System Settings historically tops out well under a day.
    return minutes >= 0 && minutes <= (24 * 60);
}

+ (int)runExecutable:(NSString *)path arguments:(NSArray<NSString *> *)arguments
{
    if (path.length == 0) {
        return EINVAL;
    }
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
        return ENOENT;
    }

    NSMutableArray<NSString *> *argvStrings = [NSMutableArray arrayWithObject:path];
    if (arguments.count > 0) {
        [argvStrings addObjectsFromArray:arguments];
    }

    NSUInteger count = argvStrings.count;
    char **argv = calloc(count + 1, sizeof(char *));
    if (argv == NULL) {
        return ENOMEM;
    }

    for (NSUInteger i = 0; i < count; i++) {
        const char *utf8 = [argvStrings[i] UTF8String];
        if (utf8 == NULL) {
            for (NSUInteger j = 0; j < i; j++) {
                free(argv[j]);
            }
            free(argv);
            return EILSEQ;
        }
        argv[i] = strdup(utf8);
        if (argv[i] == NULL) {
            for (NSUInteger j = 0; j < i; j++) {
                free(argv[j]);
            }
            free(argv);
            return ENOMEM;
        }
    }
    argv[count] = NULL;

    pid_t pid = 0;
    int spawnStatus = posix_spawn(&pid, [path fileSystemRepresentation], NULL, NULL, argv, environ);

    for (NSUInteger i = 0; i < count; i++) {
        free(argv[i]);
    }
    free(argv);

    if (spawnStatus != 0) {
        return spawnStatus;
    }

    int waitStatus = 0;
    if (waitpid(pid, &waitStatus, 0) < 0) {
        return errno;
    }
    if (WIFEXITED(waitStatus)) {
        return WEXITSTATUS(waitStatus);
    }
    if (WIFSIGNALED(waitStatus)) {
        return 128 + WTERMSIG(waitStatus);
    }
    return ECHILD;
}

+ (NSArray<NSString *> *)argumentsForTmutilEnable
{
    return @[ @"enable" ];
}

+ (NSArray<NSString *> *)argumentsForTmutilDisable
{
    return @[ @"disable" ];
}

+ (NSArray<NSString *> *)argumentsForTmutilStartBackup
{
    return @[ @"startbackup" ];
}

+ (NSArray<NSString *> *)argumentsForTmutilStopBackup
{
    return @[ @"stopbackup" ];
}

+ (NSArray<NSString *> *)argumentsForFirewallEnable
{
    return @[ @"--setglobalstate", @"on" ];
}

+ (NSArray<NSString *> *)argumentsForFirewallDisable
{
    return @[ @"--setglobalstate", @"off" ];
}

+ (NSArray<NSString *> *)argumentsForDisplaySleepMinutes:(NSInteger)minutes
{
    return @[ @"-a", @"displaysleep", [NSString stringWithFormat:@"%ld", (long)minutes] ];
}

+ (NSArray<NSString *> *)argumentsForPrinterSharingEnable
{
    return @[ @"--share-printers" ];
}

+ (NSArray<NSString *> *)argumentsForPrinterSharingDisable
{
    return @[ @"--no-share-printers" ];
}

+ (NSArray<NSString *> *)argumentsForSMBEnable
{
    return @[ @"load", @"-F", kCPHelperPathSMBDPlist ];
}

+ (NSArray<NSString *> *)argumentsForSMBDisable
{
    return @[ @"unload", @"-F", kCPHelperPathSMBDPlist ];
}

+ (NSArray<NSString *> *)argumentsForRemoteLoginEnable
{
    return @[ @"-setremotelogin", @"on" ];
}

+ (NSArray<NSString *> *)argumentsForRemoteLoginDisable
{
    return @[ @"-setremotelogin", @"off" ];
}

@end
