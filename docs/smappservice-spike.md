> **Historical decision record.** The `SMAppService` daemon path has shipped. This spike is not the current install path — do not bless via `SMJobBless` today. Current topology: [docs/signing.md](signing.md).

# Spike: SMJobBless → SMAppService daemon (#125)

Design-only. **No production helper migration in this change.** Parent epic: [#116](https://github.com/scottdensmore/ControlPlane/issues/116).

## Goal

Decide whether ControlPlane should replace `SMJobBless` installation of `com.scottdensmore.CPHelperTool` with an `SMAppService` **LaunchDaemon** on the Tahoe / macOS 26 line (`MACOSX_DEPLOYMENT_TARGET` **16.0**), using **public APIs only**.

## Current topology (as of `docs/signing.md`)

```text
Action → Action+XPCHelperTool
      → CPXPCService (embedded XPC)
         → SMJobBless(kSMDomainSystemLaunchd, …)
         → copies helper → /Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool
         → installs launchd job → /Library/LaunchDaemons/…
         → returns Mach endpoint + AuthorizationExternalForm
      → app talks to CPHelperTool over that endpoint (NSXPCConnectionPrivileged)
```

Facts that constrain migration:

- Blessing runs inside **CPXPCService**, not the main app Info.plist (`SMPrivilegedExecutables` / `SMAuthorizedClients` pair).
- Helper label / Mach service: `com.scottdensmore.CPHelperTool` (`Common/CPCommonConstants.h`).
- Main app is `LSUIElement` (menu-bar agent). Start at Login already uses **`SMAppService.mainAppService`** (`CPLoginItemService`) with `RequiresApproval` → `openSystemSettingsLoginItems`.
- Release builds are already Developer ID + notarized; unsigned CI cannot bless today and would also be unable to exercise daemon registration.

## Target topology (SMAppService daemon)

Apple’s public replacement for privileged helpers on macOS 13+:

```text
Action → (optional thin XPC façade, or direct from app)
      → SMAppService daemonServiceWithPlistName:@"com.scottdensmore.CPHelperTool.plist"
      → registerAndReturnError:  (subject to user / admin approval)
      → LaunchDaemon plist lives in app bundle:
           Contents/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist
      → executable stays in-bundle (typically Contents/MacOS/… via BundleProgram)
      → after approval, launchd publishes MachServices in the *system* domain
      → app/XPC connects with NSXPCConnectionPrivileged to the Mach name
```

Compared to SMJobBless:

| Concern | SMJobBless (today) | SMAppService daemon |
| :--- | :--- | :--- |
| Install location | `/Library/PrivilegedHelperTools` + `/Library/LaunchDaemons` | Stays **inside** the `.app` (relative paths / `BundleProgram`) |
| Registration API | `SMJobBless` + `AuthorizationRef` | `-[SMAppService registerAndReturnError:]` |
| Trust / client allowlist | Plist `SMAuthorizedClients` / `SMPrivilegedExecutables` | Bundle + Team ID; **runtime** XPC client checks in the helper |
| User consent | Auth dialog at bless time | System Settings → Login Items & Extensions (Background Items) + admin auth for daemons |
| Uninstall | Remove system files (`Utilities/Uninstall.sh`) | `unregisterAndReturnError:` (+ still clean legacy system copies during cutover) |
| Notarization | Required for distribution; bless works for signed Dev builds locally | Apple: apps that **contain** LaunchDaemons **must be notarized** for the supported path |
| API status | Deprecated | Current public API (macOS 13+) |

`SMAppService` login-item / agent / daemon factories are all public (`ServiceManagement`). ControlPlane already depends on this framework for Start at Login.

## Entitlements and signing

- Keep **Hardened Runtime** on app, any remaining XPC service, and the helper. Do **not** grant `com.apple.security.cs.disable-library-validation` to the helper (Sparkle remains app-only — unchanged).
- **No App Sandbox** (unchanged product constraint).
- App and helper must share Team ID `27ZDER873F`. Designated requirements for XPC clients should continue to use **team OU**, not a personal CN (same spirit as `HelperSigningRequirementTests`).
- Drop reliance on `SMAuthorizedClients` / `SMPrivilegedExecutables` for the daemon path. Those keys are the SMJobBless contract. For SMAppService, **enforce** “who may talk to root” in `NSXPCListenerDelegate` `shouldAcceptNewConnection:` (audit connecting process code signing / Team ID / identifier). Shipping without that check would let any local process that discovers the Mach name drive the helper as root.
- Bundle layout for implementation (not done here): copy LaunchDaemon plist into `Contents/Library/LaunchDaemons/`; use `BundleProgram` so relocating the app under `/Applications` still works. Prefer installing the product under `/Applications` so boot-time daemon bootstrap can find the bundle before login.
- Re-register (and often unregister-then-register) when the embedded daemon binary or plist changes across updates.

## User approval UX (`LSUIElement` fit)

Daemons registered with `SMAppService` are **not** bootstrapped until an admin enables them in System Settings. Status values mirror what Start at Login already handles:

- `SMAppServiceStatusNotRegistered` / `NotFound`
- `RequiresApproval` → guide user via `+[SMAppService openSystemSettingsLoginItems]`
- `Enabled` → safe to open privileged XPC

**LSUIElement fit:** acceptable. Menu-bar apps cannot rely on a Dock icon to surface Settings; ControlPlane already deep-links for login items. A migration must add an explicit prefs / first-privileged-action sheet (“Allow ControlPlane’s privileged helper in Login Items & Extensions”) and poll/observe status until `Enabled`, same pattern as `CPLoginItemService`.

Risks unique to this product:

- Users who blessed under SMJobBless will need a one-time cutover explanation; silent dual-install is worse than a clear prompt.
- MDM: Background Task Management / `com.apple.servicemanagement` payloads can pre-approve by Team ID; document for managed fleets, do not invent private approval APIs.

## Uninstall / cutover

Today: `Utilities/Uninstall.sh` boots out `system/com.scottdensmore.CPHelperTool` and deletes `/Library/LaunchDaemons` + `/Library/PrivilegedHelperTools` copies, then clears Authorization DB rights.

After SMAppService:

1. Call `unregisterAndReturnError:` for the daemon service (from the signed app).
2. On upgrade from SMJobBless builds: **also** run the legacy system-path cleanup so two helpers never answer the same Mach name.
3. Keep Authorization rights setup (`CPAuthorization`) unless an implement slice deliberately collapses that model; registration approval ≠ per-command Authorization rights.
4. Update uninstall docs / scripts in the same PR that ships the cutover.

## Notarization and local debug

- **Release:** already notarize + staple the whole app; embedded LaunchDaemon rides along. Aligns with Apple’s “apps that contain LaunchDaemons must be notarized.”
- **Local Debug:** Developer ID or Development signing with the same Team ID can register for the signed developer; CI `CODE_SIGNING_ALLOWED=NO` still cannot validate the path. Document a signed Debug smoke checklist parallel to today’s bless smoke in `signing.md`.
- Sparkle updates replace the bundle that owns the relative daemon paths — plan re-register on first launch after update.

## Explicit: no private APIs

Out of scope / disallowed for any follow-up implementation:

- Private Service Management / launchd SPI to skip System Settings approval
- Undocumented Background Task Management bypasses outside MDM configuration profiles
- Private Authorization or TCC hooks to auto-enable daemons
- Reviving gated/private helper command surfaces while migrating install tech

Public surface only: `SMAppService` (`daemonServiceWithPlistName:`, `registerAndReturnError:`, `unregisterAndReturnError:`, `status`, `openSystemSettingsLoginItems`), standard `NSXPCConnection` / listener APIs, existing Authorization rights where still needed.

## Options considered

| Option | Fit | Complexity | Risk |
| :--- | :--- | :--- | :--- |
| **A. Stay on SMJobBless for Tahoe** | Works today; docs/tests already cover it | None now | Deprecation debt; eventual removal; topology stays “legacy” |
| **B. Migrate to SMAppService daemon on Tahoe line** | Matches deploy 16.0; public API; prior art for approval UX | Medium–high (bundle layout, authz in helper, cutover, UX, docs) | High during cutover; manageable with thin slices |
| **C. Collapse CPXPCService into app-owned registration in the same change** | Fewer hops | Higher | Blends two refactors; harder to verify |

## Recommendation

### **GO — migrate on the Tahoe / macOS 26 line (follow-up implement issue)**

Reasons:

1. Deployment target is already **16.0**; `SMAppService` daemons have been the documented replacement since macOS 13.
2. In-repo **public** prior art for register / `RequiresApproval` / System Settings deep-link (`CPLoginItemService`).
3. `LSUIElement` is not a technical blocker if prefs + privileged-action UX teach Background Items approval.
4. Notarization and Team-ID signing are already product requirements; they are prerequisites, not new inventions.
5. Staying on deprecated `SMJobBless` without a scheduled cutover increases long-term helper risk while #116 already calls out helper modernization.

**Not in this PR:** no code migration. Implementation should be a dedicated issue with thin slices, for example:

1. Bundle LaunchDaemon layout + register/unregister + status UX (no command cutover).
2. Privileged XPC connect path with **mandatory** client code-signing checks; dual-run or feature-flag against SMJobBless.
3. Remove `SMJobBless` from CPXPCService; legacy uninstall; update `docs/signing.md` / smoke / tests.
4. Decide whether CPXPCService remains as Authorization/endpoint façade or shrinks (prefer **not** collapsing it in slice 1 — option C deferred).

## Non-goals (this spike)

- Shipping helper migration code
- Broadening helper command surface
- Enabling App Sandbox
- Private approval bypasses
