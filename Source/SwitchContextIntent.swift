//
//  SwitchContextIntent.swift
//  ControlPlane
//
//  App Intent so Shortcuts and Spotlight can force a named context.
//  Performed in-process against CPController; does not activate a window.
//

import AppIntents

struct ControlPlaneContextEntity: AppEntity, Identifiable, Sendable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Context")
    static var defaultQuery = ControlPlaneContextQuery()

    var id: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct ControlPlaneContextQuery: EntityStringQuery {
    func entities(for identifiers: [ControlPlaneContextEntity.ID]) async throws -> [ControlPlaneContextEntity] {
        let known = Set(CPContextAppIntentBridge.orderedContextTokens())
        return identifiers.compactMap { identifier in
            known.contains(identifier) ? ControlPlaneContextEntity(id: identifier) : nil
        }
    }

    func entities(matching string: String) async throws -> [ControlPlaneContextEntity] {
        let needle = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.entities(matching: needle, in: CPContextAppIntentBridge.orderedContextTokens())
    }

    func suggestedEntities() async throws -> [ControlPlaneContextEntity] {
        CPContextAppIntentBridge.orderedContextTokens().map { ControlPlaneContextEntity(id: $0) }
    }

    static func entities(matching needle: String, in tokens: [String]) -> [ControlPlaneContextEntity] {
        tokens.compactMap { token in
            if needle.isEmpty || token.localizedCaseInsensitiveContains(needle) {
                return ControlPlaneContextEntity(id: token)
            }
            return nil
        }
    }
}

struct SwitchContextIntent: AppIntent {
    static var title: LocalizedStringResource = "Switch Context"
    static var description = IntentDescription(
        "Force ControlPlane to a named context, the same way the status menu does."
    )

    /// Stay a background menu-bar agent. Do not order a window front or
    /// clear LSUIElement.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Context", description: "Context name, as shown in the Force Context menu")
    var context: ControlPlaneContextEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Switch to \(\.$context)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try CPContextAppIntentBridge.forceSwitch(toContextNamed: context.id)
        return .result(dialog: "Switched to \(context.id)")
    }
}

struct ControlPlaneAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SwitchContextIntent(),
            phrases: [
                "Switch context in \(.applicationName)",
                "Switch to \(\.$context) in \(.applicationName)",
            ],
            shortTitle: "Switch Context",
            systemImageName: "arrow.triangle.2.circlepath"
        )
    }
}
