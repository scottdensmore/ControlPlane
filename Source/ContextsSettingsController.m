//
//  ContextsSettingsController.m
//  ControlPlane
//

#import "ContextsSettingsController.h"
#import "ContextsDataSource.h"
#import "ControlPlane-Swift.h"

static NSString *const kContextsChangedNotification = @"ContextsChangedNotification";

@interface ContextsSettingsController ()
@property (nonatomic, weak) ContextsDataSource *dataSource;
@property (nonatomic, strong) ContextsSettingsViewModel *viewModel;
@property (nonatomic, strong) NSViewController *hostedViewController;
@end

@implementation ContextsSettingsController

- (instancetype)initWithDataSource:(ContextsDataSource *)dataSource
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _dataSource = dataSource;

    __weak ContextsSettingsController *weakSelf = self;
    _viewModel = [[ContextsSettingsViewModel alloc]
        initOnAdd:^{
            [weakSelf.dataSource newContextPromptingForName:nil];
        }
        onRemove:^{
            [weakSelf.dataSource removeContext:nil];
        }
        onEdit:^{
            [weakSelf.dataSource editSelectedContext:nil];
        }
        onSelect:^(NSString *_Nullable uuid) {
            [weakSelf.dataSource selectContextWithUUID:uuid];
        }];

    _hostedViewController = [ContextsSettingsHost makeViewControllerWithModel:_viewModel];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextsChanged:)
                                                 name:kContextsChangedNotification
                                               object:nil];

    [self reloadRows];

    return self;
}

- (NSView *)view
{
    return self.hostedViewController.view;
}

- (void)contextsChanged:(NSNotification *)note
{
    (void)note;
    [self reloadRows];
}

- (void)reloadRows
{
    NSMutableArray<ContextsSettingsRow *> *rows = [NSMutableArray array];
    for (Context *ctxt in [self.dataSource orderedTraversal]) {
        [rows addObject:[[ContextsSettingsRow alloc] initWithId:ctxt.uuid
                                                             name:ctxt.name ?: @""
                                                            depth:ctxt.depth.integerValue]];
    }
    [self.viewModel replaceRows:rows];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
