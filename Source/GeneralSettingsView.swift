//
//  GeneralSettingsView.swift
//  ControlPlane
//
//  SwiftUI General Settings pane (#203): Use Notifications, Start at Login,
//  and Allow privileged helper. Hosted inside the existing AppKit prefs shell
//  via NSHostingController (docs/swiftui-coexistence-spike.md) — AppKit still
//  owns the window / lifecycle; this view only paints the three migrated
//  General controls. Every toggle change is forwarded back to the existing
//  ObjC services (CPLoginItemService / CPHelperDaemonService / notifications
//  defaults) through `GeneralSettingsController`, so helper registration,
//  login item behavior, and the NSAlert failure flows stay exactly as before.
//
//  Accessibility ids stay stable across the migration:
//    prefs.general.useNotifications, prefs.general.startAtLogin,
//    prefs.general.allowPrivilegedHelper
//  (Pane-root prefs.tab.general stays on generalPrefsView in PrefsWindowController.)
//

import SwiftUI
import AppKit

/// Bridges SwiftUI state to the existing ObjC `PrefsWindowController` logic.
/// `NSObject`-backed and `@objc` so an ObjC host (`GeneralSettingsController`)
/// can create and refresh it without ObjC needing to name Swift generics.
///
/// The `apply*` closures receive the requested new value and must return the
/// *actual* resulting value: login-item / helper registration can fail or
/// require approval (opening System Settings + an alert), so the toggle must
/// reflect reality, not the optimistic request.
@objc(GeneralSettingsViewModel)
public final class GeneralSettingsViewModel: NSObject, ObservableObject {
    @Published var useNotifications: Bool
    @Published var startAtLogin: Bool
    @Published var allowPrivilegedHelper: Bool

    private let applyUseNotifications: (Bool) -> Bool
    private let applyStartAtLogin: (Bool) -> Bool
    private let applyAllowPrivilegedHelper: (Bool) -> Bool

    @objc public init(
        useNotifications: Bool,
        startAtLogin: Bool,
        allowPrivilegedHelper: Bool,
        applyUseNotifications: @escaping (Bool) -> Bool,
        applyStartAtLogin: @escaping (Bool) -> Bool,
        applyAllowPrivilegedHelper: @escaping (Bool) -> Bool
    ) {
        self.useNotifications = useNotifications
        self.startAtLogin = startAtLogin
        self.allowPrivilegedHelper = allowPrivilegedHelper
        self.applyUseNotifications = applyUseNotifications
        self.applyStartAtLogin = applyStartAtLogin
        self.applyAllowPrivilegedHelper = applyAllowPrivilegedHelper
        super.init()
    }

    /// Refresh toggle state from the underlying services, e.g. when the prefs
    /// window reopens (mirrors the old `startAtLoginStatus` refresh in
    /// `-runPreferences:`). Assigning `@Published` directly here does not
    /// re-invoke the `apply*` closures, so this cannot recurse or re-trigger
    /// alerts/registration.
    @objc public func refresh(startAtLogin: Bool, allowPrivilegedHelper: Bool) {
        self.startAtLogin = startAtLogin
        self.allowPrivilegedHelper = allowPrivilegedHelper
    }

    func setUseNotifications(_ newValue: Bool) {
        useNotifications = applyUseNotifications(newValue)
    }

    func setStartAtLogin(_ newValue: Bool) {
        startAtLogin = applyStartAtLogin(newValue)
    }

    func setAllowPrivilegedHelper(_ newValue: Bool) {
        allowPrivilegedHelper = applyAllowPrivilegedHelper(newValue)
    }
}

/// SwiftUI General Settings pane hosted beside the remaining AppKit General
/// controls (Enable automatic switching, confidence, default context, menu
/// bar options, etc. stay in the XIB — out of scope for #203).
struct GeneralSettingsView: View {
    @ObservedObject var model: GeneralSettingsViewModel

    var body: some View {
        Form {
            Toggle(
                NSLocalizedString("Use Notifications", comment: "General settings notifications toggle"),
                isOn: Binding(
                    get: { model.useNotifications },
                    set: { model.setUseNotifications($0) }
                )
            )
            .toggleStyle(.checkbox)
            .accessibilityIdentifier("prefs.general.useNotifications")

            Toggle(
                NSLocalizedString("Start ControlPlane at login", comment: "General settings start at login toggle"),
                isOn: Binding(
                    get: { model.startAtLogin },
                    set: { model.setStartAtLogin($0) }
                )
            )
            .toggleStyle(.checkbox)
            .accessibilityIdentifier("prefs.general.startAtLogin")

            Toggle(isOn: Binding(
                get: { model.allowPrivilegedHelper },
                set: { model.setAllowPrivilegedHelper($0) }
            )) {
                Text(CPHelperDaemonService.allowHelperCheckboxTitle())
            }
            .toggleStyle(.checkbox)
            .help(CPHelperDaemonService.allowHelperCheckboxToolTip())
            .accessibilityIdentifier("prefs.general.allowPrivilegedHelper")
        }
        .padding(12)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// ObjC-callable factory so `GeneralSettingsController` never needs to name
/// `NSHostingController<GeneralSettingsView>` (a generic Swift type) from ObjC.
@objc(GeneralSettingsHost)
public final class GeneralSettingsHost: NSObject {
    @objc public static func makeViewController(model: GeneralSettingsViewModel) -> NSViewController {
        NSHostingController(rootView: GeneralSettingsView(model: model))
    }
}
