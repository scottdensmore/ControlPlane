//
//  ContextsDataSource.h
//  ControlPlane
//
//  Created by David Symonds on 3/07/07.
//


@interface Context : NSObject

// Persistent
@property (nonatomic,strong,readonly) NSString *uuid;
@property (nonatomic,copy,readwrite) NSString *parentUUID;
@property (nonatomic,copy,readwrite) NSString *name;
@property (nonatomic,copy,readwrite) NSColor  *iconColor;

// Transient
@property (nonatomic,copy,readwrite) NSNumber *confidence;
@property (nonatomic,strong,readonly) NSNumber *depth;

- (id)init;
- (id)initWithDictionary:(NSDictionary *)dict;

- (BOOL)isRoot;
- (NSDictionary *)dictionary;
- (NSComparisonResult)compare:(Context *)ctxt;

@end


@class SliderWithValue;

@interface ContextsDataSource : NSObject

- (void)loadContexts;
- (void)saveContexts:(id)arg;

- (void)updateConfidencesFromGuesses:(NSDictionary *)guesses;

- (Context *)createContextWithName:(NSString *)name fromUI:(BOOL)fromUI;

- (IBAction)newContextPromptingForName:(id)sender;
- (IBAction)newContextSheetAccepted:(id)sender;
- (IBAction)newContextSheetRejected:(id)sender;
- (IBAction)removeContext:(id)sender;
- (IBAction)editSelectedContext:(id)sender;

// Selects the outline row matching uuid (or clears the selection if uuid is
// nil/empty/unknown). Used by ContextsSettingsController to keep the
// SwiftUI-hosted list and the AppKit outline view's selection in sync (#229).
- (void)selectContextWithUUID:(NSString *)uuid;

- (Context *)contextByUUID:(NSString *)uuid;
- (Context *)contextByName:(NSString *)name;
- (NSArray *)arrayOfUUIDs;
- (NSArray *)orderedTraversal;
- (NSArray *)orderedTraversalRootedAt:(NSString *)uuid;
- (NSArray *)walkToRoot:(NSString *)uuid;
- (NSArray *)walkFrom:(NSString *)src_uuid to:(NSString *)dst_uuid;
- (NSString *)pathFromRootTo:(NSString *)uuid;
- (NSMenu *)hierarchicalMenu;
- (NSDictionary *) getAllContexts;

- (void)triggerOutlineViewReloadData:(NSNotification *)notification;

@end
