//
//  DSLogger.m
//  ControlPlane
//
//  Created by David Symonds on 22/07/07.
//  Modified by Vladimir Beloborodov on 01 Apr 2013.
//
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//  Unified logging: os_log with categories; ring buffer retained for Advanced prefs.
//

#import <os/log.h>
#import "DSLogger.h"

NSString * const DSLoggerCategoryEvidence = @"Evidence";
NSString * const DSLoggerCategoryRules = @"Rules";
NSString * const DSLoggerCategoryActions = @"Actions";
NSString * const DSLoggerCategoryHelper = @"Helper";
NSString * const DSLoggerCategoryGeneral = @"General";

#pragma mark -
#pragma mark DSLogRecord (used by DSLogger)

@interface DSLogRecord : NSObject

@property (strong,nonatomic) NSDate   *timeStamp;
@property (strong,nonatomic) NSString *functionName;
@property (strong,nonatomic) NSString *infoMsg;

@end

@implementation DSLogRecord

- (id)initWithTimeStamp:(NSDate *)date functionName:(NSString *)name info:(NSString *)info {
    self = [super init];
    if (self) {
        _timeStamp = date;
        _functionName = name;
        _infoMsg = info;
    }
    return self;
}

- (void)setTimeStamp:(NSDate *)date functionName:(NSString *)name info:(NSString *)info {
    self.timeStamp = date;
    self.functionName = name;
    self.infoMsg = info;
}

static NSDateFormatter *timestampFormatter;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timestampFormatter = [[NSDateFormatter alloc] init];
        [timestampFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [timestampFormatter setDateFormat:@"HH:mm:ss.SSS"];
    });
}

- (NSString *)getLogRecordString {
    if (self.timeStamp) {
        NSMutableString *buf = [[NSMutableString alloc] initWithString:@"\n"];
        [buf appendString:[timestampFormatter stringFromDate:self.timeStamp]];
        [buf appendString:@" "];
        [buf appendString:self.functionName];
        [buf appendString:@"\n\t"];
        [buf appendString:self.infoMsg];
        
        self.infoMsg = buf;
        self.timeStamp = nil;
    }

    return self.infoMsg;
}

@end


#pragma mark -
#pragma mark DSLogger

#define DSLOGGER_CAPACITY	128u

@interface DSLogger ()

@property (strong,atomic,readwrite) NSDate *lastUpdatedAt;

@end

@implementation DSLogger {
    dispatch_queue_t serialQueue;

#ifdef DEBUG_MODE
	// Clustering
	NSDate *clusterStartDate;
	NSString *lastFunction;
#endif

	// Ring buffer
	NSMutableArray *buffer;
	unsigned int startIndex, count;
}

static DSLogger *sharedLogger = nil;
static NSString * const kDSLoggerSubsystem = @"com.scottdensmore.ControlPlane";

static os_log_t DSLoggerOSLogForCategory(NSString *category) {
    static os_log_t evidenceLog;
    static os_log_t rulesLog;
    static os_log_t actionsLog;
    static os_log_t helperLog;
    static os_log_t generalLog;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        evidenceLog = os_log_create(kDSLoggerSubsystem.UTF8String, DSLoggerCategoryEvidence.UTF8String);
        rulesLog = os_log_create(kDSLoggerSubsystem.UTF8String, DSLoggerCategoryRules.UTF8String);
        actionsLog = os_log_create(kDSLoggerSubsystem.UTF8String, DSLoggerCategoryActions.UTF8String);
        helperLog = os_log_create(kDSLoggerSubsystem.UTF8String, DSLoggerCategoryHelper.UTF8String);
        generalLog = os_log_create(kDSLoggerSubsystem.UTF8String, DSLoggerCategoryGeneral.UTF8String);
    });

    if ([category isEqualToString:DSLoggerCategoryEvidence]) {
        return evidenceLog;
    }
    if ([category isEqualToString:DSLoggerCategoryRules]) {
        return rulesLog;
    }
    if ([category isEqualToString:DSLoggerCategoryActions]) {
        return actionsLog;
    }
    if ([category isEqualToString:DSLoggerCategoryHelper]) {
        return helperLog;
    }
    return generalLog;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLogger = [[self alloc] init];
    });
}

+ (DSLogger *)sharedLogger {
	return sharedLogger;
}

+ (NSString *)unifiedLoggingSubsystem {
    return kDSLoggerSubsystem;
}

- (id)init {
	if (!(self = [super init])) {
		return nil;
    }

#ifdef DEBUG_MODE
	// Clustering
	clusterStartDate = [NSDate distantPast];
	lastFunction = [[NSString alloc] init];
#endif

	buffer = [[NSMutableArray alloc] initWithCapacity:DSLOGGER_CAPACITY];
	startIndex = count = 0u;

    serialQueue = dispatch_queue_create("com.scottdensmore.ControlPlane.DSLogger", DISPATCH_QUEUE_SERIAL);
    if (!serialQueue) {
        self = nil;
        return nil;
    }

    _lastUpdatedAt = [NSDate distantPast];
    
	return self;
}

- (void)dealloc {
    serialQueue = nil;
}

- (void)logFromFunction:(NSString *)fnName withInfo:(NSString *)info {
    [[self class] logFromFunction:fnName category:DSLoggerCategoryGeneral withInfo:info];
}

+ (void)logFromFunction:(NSString *)fnName withInfo:(NSString *)info {
    [self logFromFunction:fnName category:DSLoggerCategoryGeneral withInfo:info];
}

+ (void)logFromFunction:(NSString *)fnName category:(NSString *)category withInfo:(NSString *)info {
    NSString *safeCategory = category.length ? category : DSLoggerCategoryGeneral;
    os_log_t log = DSLoggerOSLogForCategory(safeCategory);
    os_log(log, "%{public}@ %{public}@", fnName ?: @"", info ?: @"");

#ifdef DEBUG_MODE
	NSLog(@"[%@] %@ %@", safeCategory, fnName, info);
#endif

    if (!sharedLogger) {
        return;
    }

    NSDate *now = [[NSDate alloc] init];
    NSString *fnNameCopy = [fnName copy], *infoCopy = [info copy];
    NSString *ringInfo = [NSString stringWithFormat:@"[%@] %@", safeCategory, infoCopy ?: @""];

    dispatch_async(sharedLogger->serialQueue, ^{
        [sharedLogger doLogFromFunction:fnNameCopy withInfo:ringInfo timeStamp:now];
    });
}

- (void)doLogFromFunction:(NSString *)func withInfo:(NSString *)info timeStamp:(NSDate *)date {
#ifdef DEBUG_MODE
    // "Clustering" all adjacent records coming from the same function within a limited timeframe
	static const NSTimeInterval clusterThreshold = 0.5; // seconds

	if (([date timeIntervalSinceDate:clusterStartDate] < clusterThreshold) && [func isEqualToString:lastFunction]) {
		info = [@"\n\t" stringByAppendingString:info];
        date = nil;
    } else {
        clusterStartDate = date;
        lastFunction = func;
	}
#endif

    if (count < DSLOGGER_CAPACITY) {
        DSLogRecord *record = [[DSLogRecord alloc] initWithTimeStamp:date functionName:func info:info];
		[buffer addObject:record];

		++count;
	} else {
		[(DSLogRecord *)buffer[startIndex] setTimeStamp:date functionName:func info:info];

        ++startIndex;
        startIndex %= DSLOGGER_CAPACITY;
	}

    self.lastUpdatedAt = [[NSDate alloc] init]; // set to now
}

- (NSString *)buffer {
	NSMutableString *buf = [NSMutableString string];

    dispatch_suspend(serialQueue);

	unsigned int i = startIndex;
    for (unsigned int cnt = count; cnt > 0u; --cnt) {
        [buf appendString:[(DSLogRecord *) buffer[i] getLogRecordString]];

        ++i;
        i %= DSLOGGER_CAPACITY;
	}

    dispatch_resume(serialQueue);

	return buf;
}

@end
