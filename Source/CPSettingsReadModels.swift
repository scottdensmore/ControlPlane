//
//  CPSettingsReadModels.swift
//  ControlPlane
//
//  Swift structs for SwiftUI binding, built from CPSettingsReadModelTokens /
//  CPSettingsReadModelBridge dictionaries. Pure value types: no ObjC/AppKit
//  imports here beyond Foundation.
//

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
