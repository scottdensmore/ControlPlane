//
//  DSLogger.h
//  ControlPlane
//
//  Created by David Symonds on 22/07/07.
//  Modified by Vladimir Beloborodov on 01 Apr 2013.
//  Unified logging (os_log) migration for #35.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Unified Logging subsystem for ControlPlane.
/// Stream with: log stream --predicate 'subsystem == "com.scottdensmore.ControlPlane"'
FOUNDATION_EXPORT NSString * const DSLoggerCategoryEvidence;
FOUNDATION_EXPORT NSString * const DSLoggerCategoryRules;
FOUNDATION_EXPORT NSString * const DSLoggerCategoryActions;
FOUNDATION_EXPORT NSString * const DSLoggerCategoryHelper;
FOUNDATION_EXPORT NSString * const DSLoggerCategoryGeneral;

@interface DSLogger : NSObject

@property (strong,atomic,readonly) NSDate *lastUpdatedAt;

+ (void)initialize;

+ (DSLogger *)sharedLogger;

/// Bundle-style subsystem string used with os_log_create.
+ (NSString *)unifiedLoggingSubsystem;

+ (void)logFromFunction:(NSString *)fnName withInfo:(NSString *)info;
+ (void)logFromFunction:(NSString *)fnName category:(NSString *)category withInfo:(NSString *)info;

- (id)init;
- (void)dealloc;

- (void)logFromFunction:(NSString *)fnName withInfo:(NSString *)info;
- (NSString *)buffer;

@end

#define DSLogWithCategory(cat, ...) \
	[DSLogger logFromFunction:@(__PRETTY_FUNCTION__) category:(cat) withInfo:[NSString stringWithFormat:__VA_ARGS__]]

#define DSLog(...)           DSLogWithCategory(DSLoggerCategoryGeneral, __VA_ARGS__)
#define DSLogEvidence(...)   DSLogWithCategory(DSLoggerCategoryEvidence, __VA_ARGS__)
#define DSLogRules(...)      DSLogWithCategory(DSLoggerCategoryRules, __VA_ARGS__)
#define DSLogActions(...)    DSLogWithCategory(DSLoggerCategoryActions, __VA_ARGS__)
#define DSLogHelper(...)     DSLogWithCategory(DSLoggerCategoryHelper, __VA_ARGS__)

NS_ASSUME_NONNULL_END
