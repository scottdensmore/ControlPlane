# SwiftUI Contexts Settings Pane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a SwiftUI Contexts Settings pane with create/rename/delete parity (#229), hosted in the existing AppKit prefs shell, reusing `ContextsDataSource` and the existing name sheet.

**Architecture:** Mirror #203 General: `ContextsSettingsViewModel` + `ContextsSettingsView` + `ContextsSettingsHost` (Swift) owned by `ContextsSettingsController` (ObjC), installed into `contextsPrefsView` by `PrefsWindowController`. SwiftUI list selection syncs to the (hidden) `NSOutlineView` so existing `newContextPromptingForName:`, `editSelectedContext:`, and `removeContext:` keep working. No MenuBarExtra / SwiftUI `Settings` / `@main` App.

**Tech Stack:** Objective-C + Swift 6, SwiftUI, AppKit, XCTest / XCUITest, existing `ContextsDataSource` / `Context`.

**Spec:** [docs/superpowers/specs/2026-09-13-swiftui-contexts-pane-design.md](../specs/2026-09-13-swiftui-contexts-pane-design.md)

## Global Constraints

- Tracker SSOT remains GitHub Issues (#229 / #190 / #192); do not invent a second roadmap.
- Feature branch → local `./scripts/smoke-build.sh` → squash-merge PR onto `main`. Never commit directly to `main`.
- No MenuBarExtra, no SwiftUI `Settings { }` scene, no `@main` Swift `App`.
- No App Sandbox flip.
- Pane-root id `prefs.tab.contexts` stays only on the AppKit `contextsPrefsView` container (never on the hosted SwiftUI root).
- Mutations go through `ContextsDataSource` (create/rename sheet / delete alerts) — do not reimplement persistence.
- Defer: DnD reparent, confidence column, icon-color product work, other Settings panes.
- Shipping locales for new user-visible strings: `en`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`.
- Conventional Commits; link `#229` in the PR.

---

## File structure

| File | Responsibility |
| :--- | :--- |
| `Source/ContextsSettingsView.swift` | ViewModel, SwiftUI list + Add/Remove/Edit, `ContextsSettingsHost` factory |
| `Source/ContextsSettingsController.h/.m` | ObjC host owning model + hosted `NSViewController` |
| `Source/PrefsWindowController.m` (and `.h` if needed) | `installContextsSettingsHostedView`; hide legacy outline/buttons; wire data source |
| `Source/ContextsDataSource.h/.m` | Declare `editSelectedContext:`; add `selectContextWithUUID:`; set sheet a11y ids; optional outline hide helper |
| `Source/ControlPlane-Bridging-Header.h` | Import `ContextsDataSource.h` / `Context` only if Swift must call them directly (prefer ObjC host supplying row dictionaries — see Task 2) |
| `ControlPlane.xcodeproj/project.pbxproj` | Add new sources to ControlPlane app target |
| `ControlPlaneTests/CPContextsSettingsHostTests.m` | Source assertions for ids, host symbols, install method, no duplicate pane-root id on SwiftUI host |
| `ControlPlaneUITests/ControlPlaneUITests.m` | Minimal create-context journey |
| `docs/TESTING.md` | Document `prefs.contexts.*` ids |
| `Resources/*/Localizable.strings` | New Add/Remove/Edit (and any list empty-state) strings |

---

### Task 1: Characterization tests (TDD red)

**Branch:** from latest `main` → `feat/swiftui-contexts-pane`  
(Do not implement product code on the docs design branch.)

**Files:**
- Create: `ControlPlaneTests/CPContextsSettingsHostTests.m`
- Modify: `ControlPlane.xcodeproj/project.pbxproj` (add test file to ControlPlaneTests)

**Interfaces:**
- Consumes: none yet
- Produces: failing tests that lock the symbols/ids the later tasks must satisfy

- [ ] **Step 1: Create branch from main**

```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b feat/swiftui-contexts-pane
```

- [ ] **Step 2: Write failing characterization tests**

Create `ControlPlaneTests/CPContextsSettingsHostTests.m`:

```objc
#import <XCTest/XCTest.h>

@interface CPContextsSettingsHostTests : XCTestCase
@end

@implementation CPContextsSettingsHostTests

- (NSString *)sourceTextAtRelativePath:(NSString *)relativePath {
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *path = [root stringByAppendingPathComponent:relativePath];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"%@", error);
    XCTAssertTrue(text.length > 0, @"missing %@", relativePath);
    return text;
}

- (void)testContextsSwiftUIPreservesAccessibilityIds {
    NSString *swift = [self sourceTextAtRelativePath:@"Source/ContextsSettingsView.swift"];
    XCTAssertTrue([swift containsString:@"prefs.contexts.list"]);
    XCTAssertTrue([swift containsString:@"prefs.contexts.add"]);
    XCTAssertTrue([swift containsString:@"prefs.contexts.remove"]);
    XCTAssertTrue([swift containsString:@"prefs.contexts.edit"]);
    // Pane root must NOT be set on the SwiftUI host (General lesson).
    XCTAssertFalse([swift containsString:@"prefs.tab.contexts"],
                   @"prefs.tab.contexts belongs on contextsPrefsView only");
}

- (void)testContextsHostInstallMethodExists {
    NSString *prefs = [self sourceTextAtRelativePath:@"Source/PrefsWindowController.m"];
    XCTAssertTrue([prefs containsString:@"installContextsSettingsHostedView"]);
    NSString *header = [self sourceTextAtRelativePath:@"Source/ContextsSettingsController.h"];
    XCTAssertTrue([header containsString:@"@interface ContextsSettingsController"]);
}

- (void)testContextsDataSourceExposesSelectionAndEditForHost {
    NSString *header = [self sourceTextAtRelativePath:@"Source/ContextsDataSource.h"];
    XCTAssertTrue([header containsString:@"editSelectedContext:"]);
    XCTAssertTrue([header containsString:@"selectContextWithUUID:"]);
}

- (void)testContextsSheetAccessibilityIdsDocumentedInSource {
    NSString *ds = [self sourceTextAtRelativePath:@"Source/ContextsDataSource.m"];
    XCTAssertTrue([ds containsString:@"prefs.contexts.sheet.name"]);
    XCTAssertTrue([ds containsString:@"prefs.contexts.sheet.confirm"]);
}

@end
```

Wire the file into the **ControlPlaneTests** target in `project.pbxproj` (copy the ID pattern used for `CPForceContextUITestHookTests.m` / `CPSettingsReadModelTokensTests.m`).

- [ ] **Step 3: Run tests — expect FAIL**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Expected: `CPContextsSettingsHostTests` failures (missing Swift/host files or missing symbols).

- [ ] **Step 4: Commit**

```bash
git add ControlPlaneTests/CPContextsSettingsHostTests.m ControlPlane.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
test(settings): characterize SwiftUI Contexts host and a11y ids (#229)

EOF
)"
```

---

### Task 2: SwiftUI list + ViewModel + Host

**Files:**
- Create: `Source/ContextsSettingsView.swift`
- Modify: `ControlPlane.xcodeproj/project.pbxproj` (app target)

**Interfaces:**
- Consumes: row dictionaries `{ @"id": uuid, @"name": name, @"depth": NSNumber }` supplied by ObjC via ViewModel
- Produces:
  - `@objc(ContextsSettingsViewModel)` with `@Published rows`, `selectedId`, `onAdd`/`onRemove`/`onEdit`/`onSelect` closures
  - `ContextsSettingsView`
  - `@objc(ContextsSettingsHost) +makeViewController(model:)` → `NSViewController`
  - Accessibility ids: `prefs.contexts.list|add|remove|edit` only (no `prefs.tab.contexts`)

- [ ] **Step 1: Implement `ContextsSettingsView.swift`**

```swift
import SwiftUI
import AppKit

@objc(ContextsSettingsRow)
public final class ContextsSettingsRow: NSObject, Identifiable {
    @objc public let id: String
    @objc public let name: String
    @objc public let depth: Int
    @objc public init(id: String, name: String, depth: Int) {
        self.id = id
        self.name = name
        self.depth = depth
        super.init()
    }
}

@objc(ContextsSettingsViewModel)
public final class ContextsSettingsViewModel: NSObject, ObservableObject {
    @Published var rows: [ContextsSettingsRow] = []
    @Published var selectedId: String?

    private let onAdd: () -> Void
    private let onRemove: () -> Void
    private let onEdit: () -> Void
    private let onSelect: (String?) -> Void

    @objc public init(onAdd: @escaping () -> Void,
                      onRemove: @escaping () -> Void,
                      onEdit: @escaping () -> Void,
                      onSelect: @escaping (String?) -> Void) {
        self.onAdd = onAdd
        self.onRemove = onRemove
        self.onEdit = onEdit
        self.onSelect = onSelect
        super.init()
    }

    @objc public func replaceRows(_ rows: [ContextsSettingsRow]) {
        self.rows = rows
        if let selectedId, !rows.contains(where: { $0.id == selectedId }) {
            self.selectedId = nil
            onSelect(nil)
        }
    }

    func add() { onAdd() }
    func remove() { onRemove() }
    func edit() { onEdit() }
    func select(_ id: String?) {
        selectedId = id
        onSelect(id)
    }
}

struct ContextsSettingsView: View {
    @ObservedObject var model: ContextsSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(NSLocalizedString("Add Context", comment: "Contexts settings add button")) {
                    model.add()
                }
                .accessibilityIdentifier("prefs.contexts.add")

                Button(NSLocalizedString("Remove Context", comment: "Contexts settings remove button")) {
                    model.remove()
                }
                .disabled(model.selectedId == nil)
                .accessibilityIdentifier("prefs.contexts.remove")

                Button(NSLocalizedString("Edit Context", comment: "Contexts settings edit button")) {
                    model.edit()
                }
                .disabled(model.selectedId == nil)
                .accessibilityIdentifier("prefs.contexts.edit")
            }

            List(selection: Binding(
                get: { model.selectedId },
                set: { model.select($0) }
            )) {
                ForEach(model.rows) { row in
                    Text(row.name)
                        .padding(.leading, CGFloat(row.depth) * 12.0)
                        .tag(Optional(row.id))
                }
            }
            .accessibilityIdentifier("prefs.contexts.list")
        }
        .padding(12)
    }
}

@objc(ContextsSettingsHost)
public final class ContextsSettingsHost: NSObject {
    @objc public static func makeViewController(model: ContextsSettingsViewModel) -> NSViewController {
        NSHostingController(rootView: ContextsSettingsView(model: model))
    }
}
```

Use button titles that match shipping UX intent; if Base XIB uses different English (e.g. only “+”), still add clear `NSLocalizedString` keys and translate all locales in Task 5.

- [ ] **Step 2: Add file to ControlPlane app target in `project.pbxproj`**

Follow `GeneralSettingsView.swift` PBX entries (Sources build phase + file reference + group).

- [ ] **Step 3: Build Debug (may still fail Task 1 tests for ObjC host)**

```bash
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane -configuration Debug \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=- build
```

Expected: Swift file compiles. Characterization tests for Swift ids should start passing once the file exists; host/install tests still fail until Task 3–4.

- [ ] **Step 4: Commit**

```bash
git add Source/ContextsSettingsView.swift ControlPlane.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
feat(settings): add SwiftUI Contexts list view and host factory (#229)

EOF
)"
```

---

### Task 3: ObjC `ContextsSettingsController` + data-source selection helpers

**Files:**
- Create: `Source/ContextsSettingsController.h`
- Create: `Source/ContextsSettingsController.m`
- Modify: `Source/ContextsDataSource.h`
- Modify: `Source/ContextsDataSource.m`
- Modify: `ControlPlane.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `ContextsSettingsViewModel`, `ContextsSettingsHost`, `ContextsDataSource` (`orderedTraversal`, IBActions)
- Produces:
  - `ContextsSettingsController` with `-initWithDataSource:`, `@property view`, `-reloadRows`
  - `ContextsDataSource`: `- (IBAction)editSelectedContext:(id)sender;` and `- (void)selectContextWithUUID:(NSString *)uuid;` declared in the header
  - Sheet a11y: set `prefs.contexts.sheet.name` on `newContextSheetName`; set `prefs.contexts.sheet.confirm` on the OK button (find via `newContextSheetAccepted:` action or outlet if present)

- [ ] **Step 1: Extend `ContextsDataSource.h`**

Add:

```objc
- (IBAction)editSelectedContext:(id)sender;
- (void)selectContextWithUUID:(nullable NSString *)uuid;
```

- [ ] **Step 2: Implement `selectContextWithUUID:` and sheet a11y in `ContextsDataSource.m`**

```objc
- (void)ensureContextsSheetAccessibilityIdentifiers {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        newContextSheetName.accessibilityIdentifier = @"prefs.contexts.sheet.name";
        // Prefer the OK control that sends newContextSheetAccepted:
        for (NSView *view in newContextSheet.contentView.subviews) {
            if (![view isKindOfClass:[NSButton class]]) { continue; }
            NSButton *button = (NSButton *)view;
            if (button.action == @selector(newContextSheetAccepted:)) {
                button.accessibilityIdentifier = @"prefs.contexts.sheet.confirm";
                break;
            }
        }
    });
}

- (void)selectContextWithUUID:(NSString *)uuid {
    [self ensureContextsSheetAccessibilityIdentifiers];
    NSOutlineView *strongOutlineView = outlineView;
    if (uuid.length == 0) {
        [strongOutlineView deselectAll:nil];
        return;
    }
    NSInteger rows = [strongOutlineView numberOfRows];
    for (NSInteger row = 0; row < rows; row++) {
        Context *ctxt = (Context *)[strongOutlineView itemAtRow:row];
        if ([ctxt.uuid isEqualToString:uuid]) {
            [strongOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row]
                           byExtendingSelection:NO];
            return;
        }
    }
    [strongOutlineView deselectAll:nil];
}
```

Call `[self ensureContextsSheetAccessibilityIdentifiers]` from `awakeFromNib` / `loadContexts` / first sheet presentation so ids exist before UITests.

Also call `ensureContextsSheetAccessibilityIdentifiers` at the start of `newContextPromptingForName:` and `editSelectedContext:`.

- [ ] **Step 3: Implement `ContextsSettingsController`**

`ContextsSettingsController.h`:

```objc
#import <Cocoa/Cocoa.h>
@class ContextsDataSource;

@interface ContextsSettingsController : NSObject
- (instancetype)initWithDataSource:(ContextsDataSource *)dataSource;
@property (nonatomic, readonly) NSView *view;
- (void)reloadRows;
@end
```

`ContextsSettingsController.m` (outline):

```objc
#import "ContextsSettingsController.h"
#import "ContextsDataSource.h"
#import "ControlPlane-Swift.h"

@interface ContextsSettingsController ()
@property (nonatomic, weak) ContextsDataSource *dataSource;
@property (nonatomic, strong) ContextsSettingsViewModel *viewModel;
@property (nonatomic, strong) NSViewController *hostedViewController;
@end

@implementation ContextsSettingsController

- (instancetype)initWithDataSource:(ContextsDataSource *)dataSource {
    self = [super init];
    if (!self) { return nil; }
    _dataSource = dataSource;
    __weak ContextsSettingsController *weakSelf = self;
    _viewModel = [[ContextsSettingsViewModel alloc]
        initWithOnAdd:^{ [weakSelf.dataSource newContextPromptingForName:nil]; }
              onRemove:^{ [weakSelf.dataSource removeContext:nil]; }
                onEdit:^{ [weakSelf.dataSource editSelectedContext:nil]; }
              onSelect:^(NSString *uuid) { [weakSelf.dataSource selectContextWithUUID:uuid]; }];
    _hostedViewController = [ContextsSettingsHost makeViewControllerWithModel:_viewModel];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextsChanged:)
                                                 name:@"ContextsChangedNotification"
                                               object:nil];
    [self reloadRows];
    return self;
}

- (NSView *)view { return self.hostedViewController.view; }

- (void)contextsChanged:(NSNotification *)note {
    (void)note;
    [self reloadRows];
}

- (void)reloadRows {
    NSMutableArray<ContextsSettingsRow *> *rows = [NSMutableArray array];
    for (Context *ctxt in [self.dataSource orderedTraversal]) {
        [rows addObject:[[ContextsSettingsRow alloc] initWithId:ctxt.uuid
                                                           name:ctxt.name ?: @""
                                                          depth:ctxt.depth.integerValue]];
    }
    [self.viewModel replaceRows:rows];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
```

Verify the real notification name string in `ContextsDataSource.m` (`postContextsChangedNotification`) and use that exact name.

Verify Swift generated ObjC selector names (`initWithOnAdd:onRemove:onEdit:onSelect:` / `makeViewControllerWithModel:`) match what Swift emits; adjust to the generated `ControlPlane-Swift.h` names if needed after first compile.

- [ ] **Step 4: Add controller files to the app target; build**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Expected: Swift id tests pass; install-method test still fails until Task 4.

- [ ] **Step 5: Commit**

```bash
git add Source/ContextsSettingsController.h Source/ContextsSettingsController.m \
  Source/ContextsDataSource.h Source/ContextsDataSource.m ControlPlane.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
feat(settings): ContextsSettingsController and outline selection sync (#229)

EOF
)"
```

---

### Task 4: Install hosted view in `PrefsWindowController`

**Files:**
- Modify: `Source/PrefsWindowController.m`
- Modify: `Source/PrefsWindowController.h` (only if a new property must be declared publicly; otherwise keep a class-extension property)

**Interfaces:**
- Consumes: `ContextsSettingsController`, `contextsPrefsView`, `contextsDataSource`
- Produces: `-installContextsSettingsHostedView` called from `awakeFromNib` near General install; legacy outline + +/- / gear controls hidden; hosted view fills usable area of `contextsPrefsView`

- [ ] **Step 1: Add property + install method**

In the PrefsWindowController class extension:

```objc
@property (nonatomic, strong) ContextsSettingsController *contextsSettingsController;
```

`#import "ContextsSettingsController.h"`

Implement:

```objc
- (void)installContextsSettingsHostedView
{
    if (self.contextsSettingsController != nil || contextsPrefsView == nil || contextsDataSource == nil) {
        return;
    }

    // Hide legacy AppKit contexts chrome (outline + buttons). Keep the views in
    // the hierarchy so ContextsDataSource outlets / selection sync still work.
    for (NSView *subview in contextsPrefsView.subviews) {
        subview.hidden = YES;
    }

    ContextsSettingsController *controller =
        [[ContextsSettingsController alloc] initWithDataSource:contextsDataSource];
    self.contextsSettingsController = controller;

    NSView *hostedView = controller.view;
    hostedView.frame = NSInsetRect(contextsPrefsView.bounds, 0, 0);
    hostedView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    hostedView.hidden = NO;
    [contextsPrefsView addSubview:hostedView];
}
```

Call `[self installContextsSettingsHostedView];` from `awakeFromNib` after groups are configured (near `installGeneralSettingsHostedView`).

If hiding *all* subviews before adding the host causes autoresizing issues, hide only `NSOutlineView`, `NSButton`, and `NSSegmentedControl` subclasses instead — but keep the outline view alive (hidden) for selection sync.

- [ ] **Step 2: Reload on prefs open**

In `runPreferences:` (and/or wherever General refreshes), call:

```objc
[self.contextsSettingsController reloadRows];
```

- [ ] **Step 3: Run characterization + smoke**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Expected: all `CPContextsSettingsHostTests` green; full unit suite green.

- [ ] **Step 4: Commit**

```bash
git add Source/PrefsWindowController.m Source/PrefsWindowController.h
git commit -m "$(cat <<'EOF'
feat(settings): host SwiftUI Contexts pane in AppKit prefs shell (#229)

EOF
)"
```

---

### Task 5: Localization + TESTING.md

**Files:**
- Modify: `Resources/en.lproj/Localizable.strings` (and `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`)
- Modify: `docs/TESTING.md`

**Interfaces:**
- Consumes: keys introduced in `ContextsSettingsView` (`Add Context`, `Remove Context`, `Edit Context`)
- Produces: all shipping locales contain those keys; TESTING.md lists `prefs.contexts.*`

- [ ] **Step 1: Add strings to every shipping `Localizable.strings`**

UTF-16 files — edit carefully (Xcode or `iconv`). English:

```
"Add Context" = "Add Context";
"Remove Context" = "Remove Context";
"Edit Context" = "Edit Context";
```

Translate for `de`/`fr`/`it`/`pt-PT`/`pt-BR`/`da-DK`. Where unsure, use clear natural translations; do not leave non-English locales as English copies for these three keys if sibling General strings in that locale are translated.

- [ ] **Step 2: Document ids in `docs/TESTING.md`**

Add rows next to the General a11y table:

| Id | Control |
| :--- | :--- |
| `prefs.contexts.list` | Contexts list |
| `prefs.contexts.add` | Add Context |
| `prefs.contexts.remove` | Remove Context |
| `prefs.contexts.edit` | Edit Context |
| `prefs.contexts.sheet.name` | Context name sheet field |
| `prefs.contexts.sheet.confirm` | Context name sheet OK |

Note pane root remains `prefs.tab.contexts` on the AppKit container.

- [ ] **Step 3: Run localization catalog tests if present**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Expected: `LocalizationCatalogTests` green (or extend expectations if the suite requires new keys).

- [ ] **Step 4: Commit**

```bash
git add Resources/*/Localizable.strings docs/TESTING.md
git commit -m "$(cat <<'EOF'
docs(l10n): Contexts SwiftUI strings and a11y id table (#229)

EOF
)"
```

---

### Task 6: Minimal create-context UITest

**Files:**
- Modify: `ControlPlaneUITests/ControlPlaneUITests.m`

**Interfaces:**
- Consumes: harness `OpenPrefsAtStartup`, toolbar `prefs.toolbar.contexts`, ids from Task 2/3
- Produces: `testCreateContextViaContextsPane` (or similarly named) that creates a uniquely named context and asserts it appears

- [ ] **Step 1: Add UITest**

```objc
- (void)testCreateContextViaContextsPane {
    XCUIApplication *app = [self launchWithPrefsOpen];
    XCUIElement *window = app.windows[@"prefs.window"];
    XCTAssertTrue([window waitForExistenceWithTimeout:15]);

    XCUIElement *toolbarContexts = app.toolbars.buttons[@"prefs.toolbar.contexts"];
    // If toolbar exposes identifiers differently, fall back to the documented
    // prefs.toolbar.contexts lookup used elsewhere / AX dump during authoring.
    XCTAssertTrue([toolbarContexts waitForExistenceWithTimeout:10]);
    [toolbarContexts click];

    XCUIElement *add = window.buttons[@"prefs.contexts.add"];
    XCTAssertTrue([add waitForExistenceWithTimeout:10]);
    [add click];

    NSString *name = [NSString stringWithFormat:@"UITest Context %@", NSUUID.UUID.UUIDString];
    XCUIElement *nameField = app.textFields[@"prefs.contexts.sheet.name"];
    XCTAssertTrue([nameField waitForExistenceWithTimeout:10]);
    [nameField click];
    [nameField typeText:name];

    XCUIElement *ok = app.buttons[@"prefs.contexts.sheet.confirm"];
    XCTAssertTrue([ok waitForExistenceWithTimeout:5]);
    [ok click];

    XCUIElement *list = window.scrollViews[@"prefs.contexts.list"];
    // List may surface as a SwiftUI collection/table — adjust query to the
    // element that carries prefs.contexts.list after first local AX dump.
    XCTAssertTrue([list waitForExistenceWithTimeout:10] ||
                  [window.descendantsMatchingType:XCUIElementTypeAny]
                      [@"prefs.contexts.list"].exists);
    XCTAssertTrue([window.staticTexts[name] waitForExistenceWithTimeout:10],
                  @"Created context name must appear in the Contexts list");
}
```

Author against a real AX dump if the toolbar/list queries need tightening — keep the test deterministic (unique name, no status-item clicks).

- [ ] **Step 2: Run UITest with ad-hoc signing**

```bash
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGN_IDENTITY=- test -only-testing:ControlPlaneUITests/ControlPlaneUITests/testCreateContextViaContextsPane
```

Expected: PASS (retry once if cold LSUIElement attach flakes, matching existing tests).

- [ ] **Step 3: Commit**

```bash
git add ControlPlaneUITests/ControlPlaneUITests.m
git commit -m "$(cat <<'EOF'
test(ui): create context via SwiftUI Contexts pane (#229)

EOF
)"
```

---

### Task 7: Full verify + PR

**Files:** none new (verification + PR only)

- [ ] **Step 1: Full smoke**

```bash
./scripts/smoke-build.sh
```

Expected: `SMOKE OK` (Debug + Release + unit tests).

- [ ] **Step 2: Push and open PR**

```bash
git push -u origin HEAD
gh pr create --title "feat(settings): SwiftUI Contexts pane (#229)" --body "$(cat <<'EOF'
## Summary
- Host SwiftUI Contexts list in the existing AppKit prefs shell (General #203 pattern)
- Create / rename / delete via `ContextsDataSource` + existing name sheet
- Accessibility ids `prefs.contexts.*`; pane root stays on AppKit `prefs.tab.contexts`
- Minimal create-context UITest; localize Add/Remove/Edit

Closes #229

## Acceptance criteria
- [x] Contexts pane is SwiftUI and feature-parity for create/rename/delete
- [x] UITest create-context green (selectors updated)

## Test plan
- [ ] `./scripts/smoke-build.sh`
- [ ] UITest `testCreateContextViaContextsPane` with `CODE_SIGN_IDENTITY=-`
- [ ] Manual: Contexts tab → add / rename / delete (including child-warning path)

EOF
)"
```

---

## Self-review (plan vs spec)

| Spec requirement | Task |
| :--- | :--- |
| Vision A coexistence (AppKit host, SwiftUI paint) | Global Constraints + Tasks 2–4 |
| Host controller + install into `contextsPrefsView` | Tasks 3–4 |
| List with optional depth indent; no DnD | Task 2 |
| CRUD via `ContextsDataSource` + existing sheet | Tasks 3–4 |
| A11y ids; no duplicate `prefs.tab.contexts` on SwiftUI | Tasks 1–2, 3 (sheet ids) |
| TESTING.md | Task 5 |
| L10n all shipping locales | Task 5 |
| Minimal create UITest / #204 selectors | Task 6 |
| Defer color/DnD/confidence | Global Constraints (no tasks) |

No TBD placeholders. Notification name and generated Swift selector spellings must be verified against the codebase during Task 3 (exact strings exist in `ContextsDataSource.m` / `ControlPlane-Swift.h`).
