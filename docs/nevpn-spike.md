# Spike: NEVPNManager vs Shortcuts for VPN (#129)

**Date:** 2026-09-07  
**Verdict:** **NO-GO for NEVPNManager in this agent.** Keep the gated ScriptingBridge `VPNAction`. Users should connect/disconnect VPN with **Shortcuts** (or System Settings) via existing **Run Shortcut**.

Do **not** revive ScriptingBridge / System Events VPN control.

## Why VPNAction is gated

`VPNAction` used AppleScript against System Preferences / Network to flip VPN services. That path is private-ish, prompts unpredictably, and is not a supported API on modern macOS. It stays `isActionApplicableToSystem == NO`.

## Option A — Personal VPN (`NEVPNManager`)

| Topic | Fit for ControlPlane |
| :--- | :--- |
| API | `NEVPNManager` + `NEVPNProtocol` — **Personal VPN** configs the app itself creates and owns |
| Entitlements | `com.apple.developer.networking.vpn.api` (Personal VPN). Not “control any system VPN.” |
| User approval | Creating a configuration triggers a system consent sheet. The profile lives in the VPN list as belonging to ControlPlane. |
| What it can do | Load/save **this app’s** IKEv2 (etc.) config; `startVPNTunnel` / `stopVPNTunnel` on that config. |
| What it cannot do | Connect or disconnect arbitrary VPN services already configured in System Settings (corporate, third-party clients, WireGuard apps, etc.). |
| LSUIElement | Agent can call the API, but the consent UI and VPN process affiliation are awkward for a menu-bar agent that is not a VPN product. |
| Sandbox | Prefer remaining unsandboxed. Personal VPN entitlement is a signing/provisioning change, not a reason to sandbox the whole utility. |

**Conclusion:** NEVPN is the wrong tool for “when I arrive at work, connect the VPN I already use.” It would only make sense if ControlPlane shipped its own VPN product, which is out of scope.

## Option B — Shortcuts (recommended)

macOS Shortcuts can run **Connect to VPN** / **Set VPN** (wording varies) for configurations the user already has, subject to Shortcuts’ own permissions.

ControlPlane already has:

- **Run Shortcut** — runs a named shortcut via `shortcuts`
- **Set Focus** — thin wrapper around the same idea

A user creates a shortcut that connects or disconnects their VPN, then attaches it as an arrival/departure action. No new entitlements, no helper, no private APIs.

Limitations: shortcut names are user-managed; there is no stable public API to enumerate system VPN services from a third-party LSUIElement app without TCC-heavy or private paths. That is acceptable.

## Recommendation

| Choice | Decision |
| :--- | :--- |
| Revive ScriptingBridge VPNAction | **No** |
| Ship NEVPNManager connect/disconnect for existing VPNs | **No** |
| Document Shortcuts as the replacement | **Yes** — Help → Tips and tricks, **Shortcuts recipe gallery** (Set VPN; suggested name *Connect Work VPN*) |
| Follow-up implement issue | **Not filed** — no NEVPN slice to build. Gallery is #127. |

## Manual check (Tahoe)

1. In Shortcuts, create “Connect Work VPN” using the system VPN action.
2. In ControlPlane, add **Run Shortcut** with that name on a context arrival.
3. Confirm the gated **VPN** action is not offered for new rules and that legacy configs fail clearly.
