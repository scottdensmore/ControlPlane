//
//  CPController.h
//  ControlPlane
//
//  Created by David Symonds on 1/02/07.
//  Major rework by Vladimir Beloborodov (VladimirTechMan) in Q2-Q3 2013.
//

#import "ContextsDataSource.h"
#import "EvidenceSource.h"


@interface CPController : NSObject <NSApplicationDelegate>

@property (retain,atomic,readonly) NSString *currentContextName;
@property (retain,atomic,readonly) NSString *currentContextPath;
@property (retain,atomic) NSString *activeContextsMenuHeader;

@property (readwrite) BOOL screenSaverRunning;
@property (readwrite) BOOL screenLocked;
@property (readwrite) BOOL goingToSleep;
@property (strong) NSMutableSet *activeContexts;
@property (strong) NSMutableSet *stickyActiveContexts;
@property (assign) IBOutlet NSMenuItem *activeContextsMenuItem;
@property (assign) IBOutlet NSMenuItem *currentContextNameMenuItem;
@property (assign) IBOutlet NSMenuItem *activeContextsMenuDivider;
@property (assign) IBOutlet NSMenuItem *stickForcedContextMenuItem;

@property (copy,nonatomic,readwrite) NSArray *activeRules;

/// Last rule/evidence diagnostics snapshot for the Diagnostics prefs pane (#35).
@property (copy,atomic,readonly) NSDictionary *lastDiagnosticsSnapshot;

- (ContextsDataSource *)contextsDataSource;
- (BOOL)stickyContext;

/// Rebuild diagnostics from current rules, guesses, and evidence (also updates lastDiagnosticsSnapshot).
- (NSDictionary *)refreshDiagnosticsSnapshot;

- (void)forceSwitch: (id) sender;

/// Force Context menu names (unique name, or Parent/Child path when names collide).
- (NSArray<NSString *> *)contextNamesForForcedSwitchMenu;

/// Select a context by that menu name, using the same path as the status menu.
- (BOOL)forceSwitchToContextNamed:(NSString *)name error:(NSError **)error;

- (IBAction)toggleSticky: (id) sender;

- (void)restartSwitchSmoothing;

- (void)suspendRegularUpdates;
- (void)resumeRegularUpdates;
- (void)resumeRegularUpdatesWithDelay:(int64_t)nanoseconds;
- (void)forceUpdate;

- (void)installStatusMenuItemsForConfigurationTransferWithTarget:(id)target;

- (NSString*)currentContextAsString;
+ (NSSet *) sharedActiveContexts;

@end
