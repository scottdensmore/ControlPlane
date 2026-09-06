//
//  CPPrefsSettingsShellController.m
//  ControlPlane
//
//  Settings-style preferences shell (issue #100).
//  IMPORTANT: This code is intended to be compiled for the ARC mode
//

#import "CPPrefsSettingsShellController.h"

@interface CPPrefsSettingsShellController ()
@property (nonatomic, copy) NSArray<NSString *> *paneNames;
@property (nonatomic, assign) BOOL suppressSelectionCallback;
@end

@implementation CPPrefsSettingsShellController

- (instancetype)init
{
	self = [super init];
	if (!self) {
		return nil;
	}

	self.tabStyle = NSTabViewControllerTabStyleToolbar;
	self.transitionOptions = NSViewControllerTransitionNone;
	self.canPropagateSelectedChildViewControllerTitle = NO;
	_paneNames = @[];

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.view setAccessibilityIdentifier:@"prefs.settingsShell"];
	[self.view setAccessibilityLabel:NSLocalizedString(@"Preferences", @"VoiceOver label for settings-style prefs shell")];
}

- (void)configureWithPaneGroups:(NSArray<NSDictionary *> *)groups
{
	while (self.tabViewItems.count > 0) {
		[self removeTabViewItem:self.tabViewItems.firstObject];
	}

	NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:groups.count];

	for (NSDictionary *group in groups) {
		NSString *name = group[@"name"];
		NSString *displayName = group[@"display_name"];
		NSString *iconName = group[@"icon"];
		NSView *paneView = group[@"view"];
		if (![name isKindOfClass:[NSString class]] || ![paneView isKindOfClass:[NSView class]]) {
			continue;
		}
		if (![displayName isKindOfClass:[NSString class]]) {
			displayName = name;
		}

		paneView.translatesAutoresizingMaskIntoConstraints = YES;
		paneView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

		NSViewController *child = [[NSViewController alloc] init];
		child.title = displayName;
		child.view = paneView;

		NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController:child];
		item.identifier = name;
		item.label = displayName;
		item.toolTip = displayName;
		if ([iconName isKindOfClass:[NSString class]]) {
			NSImage *image = [NSImage imageNamed:iconName];
			if (image) {
				item.image = image;
			}
		}

		[self addTabViewItem:item];
		[names addObject:name];
	}

	self.paneNames = [names copy];
}

- (NSString *)selectedPaneName
{
	NSInteger index = self.selectedTabViewItemIndex;
	if (index < 0 || index >= (NSInteger)self.paneNames.count) {
		return nil;
	}
	return self.paneNames[(NSUInteger)index];
}

- (NSInteger)indexOfPaneNamed:(NSString *)name
{
	if (name.length == 0) {
		return NSNotFound;
	}
	NSUInteger idx = [self.paneNames indexOfObject:name];
	return (idx == NSNotFound) ? NSNotFound : (NSInteger)idx;
}

- (void)selectPaneNamed:(NSString *)name
{
	NSInteger index = [self indexOfPaneNamed:name];
	if (index == NSNotFound) {
		return;
	}
	if (self.selectedTabViewItemIndex == index) {
		return;
	}

	self.suppressSelectionCallback = YES;
	self.selectedTabViewItemIndex = index;
	self.suppressSelectionCallback = NO;
}

- (void)setSelectedTabViewItemIndex:(NSInteger)selectedTabViewItemIndex
{
	[super setSelectedTabViewItemIndex:selectedTabViewItemIndex];

	if (self.suppressSelectionCallback) {
		return;
	}
	NSString *name = self.selectedPaneName;
	if (name.length > 0 && self.paneSelectionHandler) {
		self.paneSelectionHandler(name);
	}
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [super toolbar:toolbar
		       itemForItemIdentifier:itemIdentifier
	    willBeInsertedIntoToolbar:flag];
	if (!item) {
		return nil;
	}

	NSString *paneName = nil;
	if ([self.paneNames containsObject:itemIdentifier]) {
		paneName = itemIdentifier;
	} else {
		for (NSTabViewItem *tabItem in self.tabViewItems) {
			if ([tabItem.identifier isEqual:itemIdentifier] ||
			    [item.itemIdentifier isEqualToString:tabItem.identifier]) {
				paneName = tabItem.identifier;
				break;
			}
		}
	}

	if (paneName.length > 0) {
		NSString *displayName = item.label.length > 0 ? item.label : paneName;
		id axItem = item;
		[axItem setAccessibilityLabel:displayName];
		[axItem setAccessibilityIdentifier:[NSString stringWithFormat:@"prefs.toolbar.%@", [paneName lowercaseString]]];
	}

	return item;
}

@end
