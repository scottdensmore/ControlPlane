# Award UI Platform Path Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land Swift 6, dual-stack agent policy, Settings read models, and a hosted SwiftUI General pane so ControlPlane can ship award-track Settings on Tahoe without rewriting the ObjC evidence loop.

**Architecture:** AppKit owns lifecycle (`NSApplicationMain` → `CPController`); SwiftUI paints. Serial PRs: #200 → #201 → #224 → #203. Host General via `NSHostingController` inside `PrefsWindowController` / `CPPrefsSettingsShellController`. Read models mirror `CPContextAppIntentBridge` / `CPContextAppIntentTokens`.

**Tech Stack:** Objective-C + Swift 6, SwiftUI, AppKit, XCTest, existing `CPLoginItemService` / `CPHelperDaemonService`, deployment target 16.0.

**Spec:** [docs/superpowers/specs/2026-09-13-award-ui-platform-path-design.md](../specs/2026-09-13-award-ui-platform-path-design.md)

## Global Constraints

- Tracker SSOT remains GitHub Issues (#190 parent); do not invent a second roadmap.
- Feature branch → local `./scripts/smoke-build.sh` → squash-merge PR onto `main`. Never commit directly to `main`.
- No MenuBarExtra, no SwiftUI `Settings { }` scene, no `@main` Swift `App`.
- No App Sandbox flip (#280 is out of scope).
- Preserve `prefs.general.*` accessibility IDs and existing `CPHelperDaemonServiceTests` CONTRIBUTING/SMAppService assertions.
- Shipping locales for new user-visible strings: `en`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`.

---

## File structure (wave)

| File | Responsibility |
| :--- | :--- |
| `ControlPlane.xcodeproj/project.pbxproj` | `SWIFT_VERSION = 6` (Debug + Release app configs); add new Swift/ObjC sources to app + test targets |
| `Source/SwitchContextIntent.swift` | App Intent; fix any Swift 6 concurrency/isolation issues |
| `ControlPlaneTests/CPContextAppIntentTests.m` (or new `CPSwiftLanguageModeTests.m`) | Assert `SWIFT_VERSION = 6` in app configs |
| `CONTRIBUTING.md` | Dual-stack policy pointing at coexistence spike + #190 |
| GitHub issue #190 | Refresh body: `main`, local smoke, sandbox design allowed |
| `Source/CPSettingsReadModelTokens.h/.m` | Pure mapping: fixture rows → read-model dictionaries (unit-testable, no app host) |
| `Source/CPSettingsReadModelBridge.h/.m` | Live lists from `CPController` / registries on main thread |
| `Source/CPSettingsReadModels.swift` | Swift structs for SwiftUI binding (`id`, `name`, `enabled`, …) |
| `Source/ControlPlane-Bridging-Header.h` | Import new ObjC bridge headers |
| `ControlPlaneTests/CPSettingsReadModelTokensTests.m` | Mapping unit tests |
| `Source/GeneralSettingsView.swift` | SwiftUI General pane |
| `Source/GeneralSettingsHostingController.swift` (or ObjC wrapper) | `NSHostingController` bridge for prefs shell |
| `Source/PrefsWindowController.m` | Swap General tab to hosted SwiftUI; retire XIB General control wiring for migrated toggles |
| `Resources/*/Localizable.strings` | New General strings if not reusing existing keys |

---

### Task 1: Swift 6 language mode (#200)

**Branch:** from latest `main` → `feat/swift-6-language-mode`  
(Do not continue on the docs design branch for product code.)

**Files:**
- Modify: `ControlPlane.xcodeproj/project.pbxproj` (both app `SWIFT_VERSION = 5.0` → `6`)
- Modify: `Source/SwitchContextIntent.swift` (only if Swift 6 errors require it)
- Create or Modify: `ControlPlaneTests/CPSwiftLanguageModeTests.m`
- Test: `ControlPlaneTests` via smoke script

**Interfaces:**
- Consumes: existing `CPContextAppIntentBridge` / App Intent registration
- Produces: app target compiles with `SWIFT_VERSION = 6`; unit test locks it

- [ ] **Step 1: Create branch from main**

```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b feat/swift-6-language-mode
```

- [ ] **Step 2: Write the failing language-mode test**

Create `ControlPlaneTests/CPSwiftLanguageModeTests.m`:

```objc
#import <XCTest/XCTest.h>

@interface CPSwiftLanguageModeTests : XCTestCase
@end

@implementation CPSwiftLanguageModeTests

- (NSString *)projectText {
    NSString *root = @CONTROLPLANE_SRCROOT;
    NSString *path = [root stringByAppendingPathComponent:@"ControlPlane.xcodeproj/project.pbxproj"];
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(text.length > 0);
    return text;
}

- (void)testAppTargetSwiftVersionIsSix {
    NSString *project = [self projectText];
    // App Debug + Release both set SWIFT_VERSION (two occurrences today).
    NSRegularExpression *re =
        [NSRegularExpression regularExpressionWithPattern:@"SWIFT_VERSION = ([^;]+);"
                                                  options:0
                                                    error:NULL];
    NSArray<NSTextCheckingResult *> *matches =
        [re matchesInString:project options:0 range:NSMakeRange(0, project.length)];
    XCTAssertGreaterThanOrEqual(matches.count, 2u);
    for (NSTextCheckingResult *m in matches) {
        NSString *value = [project substringWithRange:[m rangeAtIndex:1]];
        XCTAssertEqualObjects(value, @"6",
                              @"App Swift sources must use SWIFT_VERSION = 6 (#200)");
    }
}

@end
```

Add the file to the **ControlPlaneTests** target in Xcode / `project.pbxproj` (follow IDs pattern of `CPContextAppIntentTests.m`).

- [ ] **Step 3: Run test to verify it fails**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Expected: `testAppTargetSwiftVersionIsSix` FAIL — values still `5.0`.

- [ ] **Step 4: Set SWIFT_VERSION to 6**

In `ControlPlane.xcodeproj/project.pbxproj`, replace both app-config lines:

```
SWIFT_VERSION = 6;
```

(Do not change unrelated targets if any appear later.)

- [ ] **Step 5: Fix Swift 6 compile errors if any**

Build:

```bash
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane -configuration Debug \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=- build
```

If `SwitchContextIntent.swift` fails isolation/Sendable checks, prefer minimal fixes:
- Keep `ControlPlaneContextEntity` `Sendable` as today
- Hop to main via existing ObjC bridge (already syncs to main in `CPContextAppIntentBridge`)
- Avoid `@MainActor` on the whole intent unless required

- [ ] **Step 6: Run tests to verify they pass**

```bash
./scripts/smoke-build.sh
```

Expected: Debug + Release build green; `ControlPlaneTests` green including `testAppTargetSwiftVersionIsSix`.

- [ ] **Step 7: Commit and open PR**

```bash
git add ControlPlane.xcodeproj/project.pbxproj Source/SwitchContextIntent.swift \
  ControlPlaneTests/CPSwiftLanguageModeTests.m
git commit -m "$(cat <<'EOF'
build: enable Swift 6 language mode for app Swift (#200)

Lock SWIFT_VERSION=6 so award-track SwiftUI can land under Swift 6 without a later break.

EOF
)"
git push -u origin HEAD
gh pr create --title "build: enable Swift 6 language mode (#200)" --body "$(cat <<'EOF'
## Summary
- Set app `SWIFT_VERSION` to 6
- Add unit assertion locking Swift 6
- Fix Intent compile issues if any

Closes #200

## Test plan
- [ ] `./scripts/smoke-build.sh`
- [ ] Confirm App Intent still listed in Shortcuts (manual smoke if available)

EOF
)"
```

Squash-merge when approved; do not start Task 2 until this is on `main`.

---

### Task 2: Dual-stack CONTRIBUTING.md + epic #190 refresh (#201)

**Branch:** `docs/agents-dual-stack` from updated `main`

**Files:**
- Modify: `CONTRIBUTING.md`
- Modify via `gh`: issue [#190](https://github.com/scottdensmore/ControlPlane/issues/190) body
- Test: existing `CPHelperDaemonServiceTests` docs assertions must stay green

**Interfaces:**
- Consumes: `docs/swiftui-coexistence-spike.md` decisions; Task 1 on `main`
- Produces: agents know AppKit-host + SwiftUI-views + Swift 6 rules

- [ ] **Step 1: Create branch**

```bash
git checkout main && git pull origin main
git checkout -b docs/agents-dual-stack
```

- [ ] **Step 2: Write / extend a failing docs assertion for dual-stack**

In `ControlPlaneTests/CPHelperDaemonServiceTests.m` (or a small new test file in ControlPlaneTests), add:

```objc
- (void)testAgentsMdDescribesDualStackSwiftUIPolicy {
    NSString *contributing = [self sourceTextAtRelativePath:@"CONTRIBUTING.md"];
    XCTAssertTrue([contributing containsString:@"SwiftUI"],
                  @"CONTRIBUTING.md must describe SwiftUI Settings/status migration");
    XCTAssertTrue([contributing containsString:@"Swift 6"],
                  @"CONTRIBUTING.md must require Swift 6 for new Swift");
    XCTAssertTrue([contributing containsString:@"swiftui-coexistence-spike.md"],
                  @"CONTRIBUTING.md must point at the coexistence spike");
    XCTAssertTrue([contributing containsString:@"#190"] || [contributing containsString:@"190"],
                  @"CONTRIBUTING.md must point at award epic #190");
    // Naming MenuBarExtra as forbidden is OK (human decision: keep explicit NO-GO wording).
}
```

If `sourceTextAtRelativePath:` is private to that class, put the test in that `@implementation` or duplicate the tiny helper.

- [ ] **Step 3: Run test — expect FAIL**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

- [ ] **Step 4: Update `CONTRIBUTING.md`**

Keep existing helper / sandbox / branching rules in `CONTRIBUTING.md`. Expand with an explicit dual-stack section (AppKit host + SwiftUI views, Swift 6, no MenuBarExtra / Settings scenes / `@main` App). **Must preserve** strings already asserted by `testAgentDocsDescribeSMAppServiceDaemonNotSMJobBlessInstall` on `CONTRIBUTING.md`.
Do **not** recreate `AGENTS.md`.

- [ ] **Step 5: Refresh GitHub epic #190**

Use `gh issue edit 190 --body "$(cat <<'EOF'
…full updated body…
EOF
)"` **or** comment with a corrected “Current constraints” section if full rewrite is risky.

Must fix stale claims:
- `main` (not `master`)
- Verification is **local** `./scripts/smoke-build.sh` — GitHub Actions disabled (no “CI after #171”)
- App Sandbox is **allowed per** `docs/sandbox-store-spike.md` / epic #278 (not a standing ban)
- Suggested start: #200 done → #201 → #224 → #203
- Keep child epic table (#191–#198, #278)

- [ ] **Step 6: Run tests**

```bash
./scripts/smoke-build.sh
```

Expected: new dual-stack assertion + existing helper docs tests green.

- [ ] **Step 7: Commit and PR**

```bash
git add CONTRIBUTING.md ControlPlaneTests/
git commit -m "$(cat <<'EOF'
docs(contributing): dual-stack SwiftUI + Swift 6 migration policy (#201)

Align CONTRIBUTING.md with the award-track coexistence model and point agents at epic #190.

EOF
)"
git push -u origin HEAD
gh pr create --title "docs(contributing): dual-stack SwiftUI + Swift 6 policy (#201)" --body "$(cat <<'EOF'
## Summary
- Dual-stack policy in CONTRIBUTING.md
- Docs assertion for SwiftUI / Swift 6 / coexistence spike
- Epic #190 text refreshed for main / local smoke / sandbox design

Closes #201

## Test plan
- [ ] `./scripts/smoke-build.sh`
- [ ] Confirm #190 body no longer mentions master, Actions re-enable, or sandbox ban

EOF
)"
```

---

### Task 3: Shared Swift read models (#224)

**Branch:** `feat/settings-read-models` from updated `main`

**Files:**
- Create: `Source/CPSettingsReadModelTokens.h`
- Create: `Source/CPSettingsReadModelTokens.m`
- Create: `Source/CPSettingsReadModelBridge.h`
- Create: `Source/CPSettingsReadModelBridge.m`
- Create: `Source/CPSettingsReadModels.swift`
- Modify: `Source/ControlPlane-Bridging-Header.h`
- Modify: `ControlPlane.xcodeproj/project.pbxproj`
- Create: `ControlPlaneTests/CPSettingsReadModelTokensTests.m`

**Interfaces:**
- Consumes: `ContextsDataSource` ordered contexts / names; `EvidenceSource` `name` / `friendlyName` / `enablementKeyName`; `ActionSetController` `types` + `friendlyName`
- Produces:
  - `+[CPSettingsReadModelTokens contextRowsFromOrderedNames:]` → `@[ @{ @"id":, @"name": } ]`
  - `+[CPSettingsReadModelTokens evidenceRowsFromDescriptors:]` → `@[ @{ @"id":, @"name":, @"enabled": } ]`
  - `+[CPSettingsReadModelTokens actionTypeRowsFromDescriptors:]` → `@[ @{ @"id":, @"name": } ]`
  - Swift: `struct SettingsContextRow: Identifiable` etc. with `init(dictionary:)`
  - Live: `+[CPSettingsReadModelBridge orderedContextRows]` etc. (main-thread, empty if no controller)

- [ ] **Step 1: Create branch**

```bash
git checkout main && git pull origin main
git checkout -b feat/settings-read-models
```

- [ ] **Step 2: Write failing mapping tests**

`ControlPlaneTests/CPSettingsReadModelTokensTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "CPSettingsReadModelTokens.h"

@interface CPSettingsReadModelTokensTests : XCTestCase
@end

@implementation CPSettingsReadModelTokensTests

- (void)testContextRowsPreserveOrderAndIds {
    NSArray *rows = [CPSettingsReadModelTokens contextRowsFromOrderedNames:@[ @"Home", @"Work" ]];
    XCTAssertEqual(rows.count, 2u);
    XCTAssertEqualObjects(rows[0][@"id"], @"Home");
    XCTAssertEqualObjects(rows[0][@"name"], @"Home");
    XCTAssertEqualObjects(rows[1][@"id"], @"Work");
}

- (void)testContextRowsIgnoreEmptyNames {
    NSArray *rows = [CPSettingsReadModelTokens contextRowsFromOrderedNames:@[ @"", @"Work", @"  " ]];
    XCTAssertEqual(rows.count, 1u);
    XCTAssertEqualObjects(rows[0][@"name"], @"Work");
}

- (void)testEvidenceRowsMapEnabledFlag {
    NSArray *rows = [CPSettingsReadModelTokens evidenceRowsFromDescriptors:@[
        @{ @"id": @"WiFi", @"name": @"Wi‑Fi", @"enabled": @YES },
        @{ @"id": @"Power", @"name": @"Power", @"enabled": @NO },
    ]];
    XCTAssertEqual(rows.count, 2u);
    XCTAssertEqualObjects(rows[0][@"enabled"], @YES);
    XCTAssertEqualObjects(rows[1][@"enabled"], @NO);
}

- (void)testActionTypeRowsPreserveTypeId {
    NSArray *rows = [CPSettingsReadModelTokens actionTypeRowsFromDescriptors:@[
        @{ @"id": @"DefaultBrowser", @"name": @"Default Browser" },
    ]];
    XCTAssertEqualObjects(rows[0][@"id"], @"DefaultBrowser");
    XCTAssertEqualObjects(rows[0][@"name"], @"Default Browser");
}

- (void)testEmptyInputsYieldEmptyArrays {
    XCTAssertEqual([CPSettingsReadModelTokens contextRowsFromOrderedNames:@[]].count, 0u);
    XCTAssertEqual([CPSettingsReadModelTokens evidenceRowsFromDescriptors:@[]].count, 0u);
    XCTAssertEqual([CPSettingsReadModelTokens actionTypeRowsFromDescriptors:nil].count, 0u);
}

@end
```

- [ ] **Step 3: Run tests — expect FAIL (missing class)**

```bash
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

- [ ] **Step 4: Implement tokens + bridge + Swift models**

`CPSettingsReadModelTokens.h`:

```objc
#import <Foundation/Foundation.h>

@interface CPSettingsReadModelTokens : NSObject
+ (NSArray<NSDictionary *> *)contextRowsFromOrderedNames:(NSArray<NSString *> *)names;
+ (NSArray<NSDictionary *> *)evidenceRowsFromDescriptors:(NSArray<NSDictionary *> *)descriptors;
+ (NSArray<NSDictionary *> *)actionTypeRowsFromDescriptors:(NSArray<NSDictionary *> *)descriptors;
@end
```

Implement mappers in `.m`: copy only known keys; skip nil/blank `id`/`name`; default `enabled` to `@NO` if missing for evidence.

`CPSettingsReadModelBridge.m` (live, main-thread hop like `CPContextAppIntentBridge`):
- Contexts: `[controller contextNamesForForcedSwitchMenu]` → tokens
- Evidence: enumerate `[evidenceSources sourceEnumerator]`; for each `EvidenceSource *src`, build descriptor `id=[src name]`, `name=[src friendlyName] ?: [src name]`, `enabled=[[NSUserDefaults standardUserDefaults] boolForKey:[src enablementKeyName]]`
- Actions: ask `ActionSetController` for `types`; for each type string, resolve class via `[Action classForType:]` and `friendlyName` when available; if ActionSetController is only reachable via nib outlet, expose a thin method on `CPController` **or** return empty actions when controller unavailable — do **not** rewrite Action matching. Prefer reading from the same prefs-owned `ActionSetController` outlet if `CPController` can provide it; otherwise ship context+evidence first and return `@[]` for actions with a comment linking follow-up — **prefer full three lists** by adding `- (NSArray<NSString *> *)registeredActionTypeIdentifiers` on a small ObjC helper that instantiates/reads the known class list without executing actions.

For live action types: instantiate or reuse `ActionSetController` and call `-types`, then map each type through `+[Action classForType:]` + `friendlyName`. If nib outlets make `init` unsafe in unit tests, keep live listing inside `CPSettingsReadModelBridge` (app process only) and cover mapping via tokens fixtures in `CPSettingsReadModelTokensTests`.

Wire bridging header:

```objc
#import "CPContextAppIntentBridge.h"
#import "CPSettingsReadModelBridge.h"
#import "CPSettingsReadModelTokens.h"
```

`CPSettingsReadModels.swift`:

```swift
import Foundation

struct SettingsContextRow: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    init(dictionary: [String: Any]) {
        let id = dictionary["id"] as? String ?? ""
        self.id = id
        self.name = (dictionary["name"] as? String) ?? id
    }
}

struct SettingsEvidenceRow: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let enabled: Bool
    init(dictionary: [String: Any]) {
        let id = dictionary["id"] as? String ?? ""
        self.id = id
        self.name = (dictionary["name"] as? String) ?? id
        self.enabled = (dictionary["enabled"] as? Bool) ?? false
    }
}

struct SettingsActionTypeRow: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    init(dictionary: [String: Any]) {
        let id = dictionary["id"] as? String ?? ""
        self.id = id
        self.name = (dictionary["name"] as? String) ?? id
    }
}
```

Add all new files to the **ControlPlane** app target; tests file to **ControlPlaneTests**.

- [ ] **Step 5: Run smoke**

```bash
./scripts/smoke-build.sh
```

Expected: mapping tests green; ObjC pipeline unchanged (no matcher edits).

- [ ] **Step 6: Commit and PR**

```bash
git add Source/CPSettingsReadModel* Source/ControlPlane-Bridging-Header.h \
  ControlPlaneTests/CPSettingsReadModelTokensTests.m ControlPlane.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
feat(bridge): shared Swift read models for Settings lists (#224)

Add pure mapping tokens and a live bridge so SwiftUI can bind Context, Evidence, and Action lists without owning ObjC matchers.

EOF
)"
git push -u origin HEAD
gh pr create --title "feat(bridge): Settings read models (#224)" --body "$(cat <<'EOF'
## Summary
- Pure mapping tokens + unit tests
- Live bridge for context / evidence / action type rows
- Swift read-model structs for upcoming SwiftUI panes

Closes #224

## Test plan
- [ ] `./scripts/smoke-build.sh`
- [ ] Confirm no Settings UI changes in this PR

EOF
)"
```

---

### Task 4: SwiftUI General pane (#203)

**Branch:** `feat/swiftui-general-pane` from updated `main` (requires Tasks 1–3 merged)

**Files:**
- Create: `Source/GeneralSettingsView.swift`
- Create: `Source/GeneralSettingsController.h/.m` (ObjC host that owns `NSHostingView` / `NSHostingController`)
- Modify: `Source/PrefsWindowController.m` — General tab uses hosted view; keep helper/login behavior
- Modify: `Resources/*/Localizable.strings` if new keys are introduced (prefer existing `NSLocalizedString` keys already used by General)
- Modify: `ControlPlane.xcodeproj/project.pbxproj`
- Possibly update: `ControlPlaneTests/CPUITestHarnessTests.m` if General AX ids move but strings must stay identical
- Docs touch: `docs/TESTING.md` only if ids/hooks change (prefer no change)

**Interfaces:**
- Consumes: `CPLoginItemService`, `CPHelperDaemonService`, notifications prefs (`EnableNotifications` via existing `ContextsDataSource` / defaults path), Task 3 bridge optional for General (General does not require list rows)
- Produces: General pane SwiftUI with ids:
  - `prefs.tab.general` (root)
  - `prefs.general.useNotifications`
  - `prefs.general.startAtLogin` (add if missing on old control; if old control lacked an id, **add** `prefs.general.startAtLogin` on the new Toggle and update UITest/docs only if a journey asserts it)
  - `prefs.general.allowPrivilegedHelper`

- [ ] **Step 1: Create branch**

```bash
git checkout main && git pull origin main
git checkout -b feat/swiftui-general-pane
```

- [ ] **Step 2: Characterization — lock current General AX ids**

Confirm in tests/docs (already present):
- `prefs.general.useNotifications`
- `prefs.general.allowPrivilegedHelper`

Add a small unit/source assertion if useful:

```objc
- (void)testGeneralSwiftUIPreservesAccessibilityIds {
    NSString *swift = [self sourceTextAtRelativePath:@"Source/GeneralSettingsView.swift"];
    XCTAssertTrue([swift containsString:@"prefs.general.useNotifications"]);
    XCTAssertTrue([swift containsString:@"prefs.general.allowPrivilegedHelper"]);
    XCTAssertTrue([swift containsString:@"prefs.tab.general"]);
}
```

First run fails (file missing) — TDD red.

- [ ] **Step 3: Implement `GeneralSettingsView`**

```swift
import SwiftUI
import AppKit

struct GeneralSettingsView: View {
    @State private var useNotifications: Bool
    @State private var startAtLogin: Bool
    @State private var allowPrivilegedHelper: Bool

    private let onNotificationsChange: (Bool) -> Void
    private let onStartAtLoginChange: (Bool) -> Void
    private let onHelperChange: (Bool) -> Void

    var body: some View {
        Form {
            Toggle("Use Notifications", isOn: $useNotifications)
                .accessibilityIdentifier("prefs.general.useNotifications")
                .onChange(of: useNotifications) { _, newValue in
                    onNotificationsChange(newValue)
                }
            Toggle("Start at Login", isOn: $startAtLogin)
                .accessibilityIdentifier("prefs.general.startAtLogin")
                .onChange(of: startAtLogin) { _, newValue in
                    onStartAtLoginChange(newValue)
                }
            Toggle(CPHelperDaemonService.allowHelperCheckboxTitle(), isOn: $allowPrivilegedHelper)
                .help(CPHelperDaemonService.allowHelperCheckboxToolTip())
                .accessibilityIdentifier("prefs.general.allowPrivilegedHelper")
                .onChange(of: allowPrivilegedHelper) { _, newValue in
                    onHelperChange(newValue)
                }
        }
        .padding()
        .accessibilityIdentifier("prefs.tab.general")
    }
}
```

Wire titles through `NSLocalizedString` / existing ObjC localized strings so all locales keep coverage — do not hardcode English in the final code. Prefer calling into ObjC helpers for checkbox titles already localized (`allowHelperCheckboxTitle`).

- [ ] **Step 4: ObjC host + PrefsWindowController integration**

`GeneralSettingsController` creates `NSHostingController` (via a tiny Swift factory `GeneralSettingsHost.makeController(...)` returning `NSViewController *` if cleaner for ObjC).

In `PrefsWindowController` `awakeFromNib` / prefs group setup:
- Replace `generalPrefsView` content (or the group’s `view`) with the hosting controller’s view
- Remove `installAllowPrivilegedHelperCheckbox` AppKit checkbox path once SwiftUI owns it (delete duplicate control)
- On toggle failures, present the same `NSAlert` flows currently in `startAtLogin` / `allowPrivilegedHelper` / open Login Items
- Refresh toggle state when prefs window opens (mirror today’s `startAtLoginStatus` refresh)

Keep opening path: status menu / ⌘, → `runPreferences:` unchanged.

- [ ] **Step 5: Localize**

If new keys appear, add them to:
`Resources/en.lproj/Localizable.strings`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`.  
Prefer reusing existing keys already in those files for “Use Notifications” / “Start at Login”.

- [ ] **Step 6: Verify**

```bash
./scripts/smoke-build.sh
```

UITest (ad-hoc sign preferred per TESTING.md):

```bash
CPUITestRunning=1 xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' CODE_SIGN_IDENTITY=- \
  test -only-testing:ControlPlaneUITests/ControlPlaneUITests/testLaunchAndOpenPreferences
```

Manual: open Settings → General; toggle notifications; confirm helper checkbox still calls `CPHelperDaemonService` (unsigned: expect failure alert, not crash).

- [ ] **Step 7: Commit and PR**

```bash
git add Source/GeneralSettings* Source/PrefsWindowController.m \
  Resources/*/Localizable.strings ControlPlane.xcodeproj/project.pbxproj ControlPlaneTests/
git commit -m "$(cat <<'EOF'
feat(settings): SwiftUI General pane hosted in AppKit shell (#203)

Ship the first award-track Settings pane without MenuBarExtra or a SwiftUI Settings scene.

EOF
)"
git push -u origin HEAD
gh pr create --title "feat(settings): SwiftUI General pane (#203)" --body "$(cat <<'EOF'
## Summary
- SwiftUI General pane in existing AppKit prefs shell
- Preserves prefs.general.* accessibility IDs
- Login item + privileged helper behavior unchanged

Closes #203

## Test plan
- [ ] `./scripts/smoke-build.sh`
- [ ] UITest OpenPrefsAtStartup smoke
- [ ] Manual: notifications + start at login + helper checkbox

EOF
)"
```

---

## Self-review (plan vs spec)

| Spec requirement | Task |
| :--- | :--- |
| #200 Swift 6 + assertion | Task 1 |
| #201 CONTRIBUTING dual-stack + #190 refresh | Task 2 |
| #224 read models + mapping tests | Task 3 |
| #203 SwiftUI General + a11y IDs + locales | Task 4 |
| Serial PR delivery / no main commits | Global Constraints + each task branch steps |
| No MenuBarExtra / Settings scene / sandbox | Global Constraints + Task 2 / 4 |
| Preserve helper docs assertions | Task 2 Step 4 |

No TBD placeholders remain. Action live rows use `ActionSetController` `-types` in the app bridge; token tests cover mapping with fixtures.
