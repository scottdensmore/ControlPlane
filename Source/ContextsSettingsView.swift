//
//  ContextsSettingsView.swift
//  ControlPlane
//
//  SwiftUI Contexts list pane (#229): list + add/remove/edit controls for
//  the Contexts prefs pane. Hosted inside the existing AppKit prefs shell
//  via NSHostingController (docs/swiftui-coexistence-spike.md) — AppKit
//  still owns the window / lifecycle and all context mutation logic lives
//  in `ContextsDataSource`; this view only paints the list + buttons and
//  forwards user intent back through the ViewModel closures.
//
//  Accessibility ids stay stable across the migration:
//    prefs.contexts.list, prefs.contexts.add, prefs.contexts.remove,
//    prefs.contexts.edit
//  (The pane-root accessibility id stays on the AppKit contextsPrefsView
//  container in PrefsWindowController — never on this SwiftUI host, per
//  the General pane lesson.)
//

import SwiftUI
import AppKit

/// Lightweight row model bridging ObjC context dictionaries
/// (`{ @"id": uuid, @"name": name, @"depth": NSNumber }`) into a
/// SwiftUI-Identifiable value the List can diff efficiently.
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

/// Bridges SwiftUI state to the existing ObjC `ContextsDataSource` /
/// `ContextsSettingsController` logic. `NSObject`-backed and `@objc` so an
/// ObjC host can create and refresh it without ObjC needing to name Swift
/// generics.
///
/// All mutations (add / remove / edit) are forwarded to ObjC via the
/// `on*` closures — this ViewModel never reimplements persistence.
@objc(ContextsSettingsViewModel)
public final class ContextsSettingsViewModel: NSObject, ObservableObject {
    @Published var rows: [ContextsSettingsRow] = []
    @Published var selectedId: String?

    private let onAdd: () -> Void
    private let onRemove: () -> Void
    private let onEdit: () -> Void
    private let onSelect: (String?) -> Void

    @objc public init(
        onAdd: @escaping () -> Void,
        onRemove: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onSelect: @escaping (String?) -> Void
    ) {
        self.onAdd = onAdd
        self.onRemove = onRemove
        self.onEdit = onEdit
        self.onSelect = onSelect
        super.init()
    }

    /// Replace the displayed rows, e.g. when the underlying
    /// `ContextsDataSource` outline changes. Clears the selection (and
    /// notifies ObjC) if the previously-selected id no longer exists.
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

/// SwiftUI Contexts list pane: add/remove/edit buttons plus the indented
/// context outline. Everything else on the Contexts prefs pane (trigger
/// list, description, etc.) stays in the XIB — out of scope for #229.
/// The pane-root accessibility id is never set here; it stays on the
/// AppKit container view that hosts this SwiftUI view.
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

/// ObjC-callable factory so `ContextsSettingsController` never needs to
/// name `NSHostingController<ContextsSettingsView>` (a generic Swift type)
/// from ObjC.
@objc(ContextsSettingsHost)
public final class ContextsSettingsHost: NSObject {
    @objc public static func makeViewController(model: ContextsSettingsViewModel) -> NSViewController {
        NSHostingController(rootView: ContextsSettingsView(model: model))
    }
}
