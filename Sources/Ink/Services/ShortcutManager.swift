import Foundation
import SwiftUI

struct ShortcutBinding: Codable, Equatable {
    var key: String
    var modifiers: ModifierFlags

    var display: String {
        modifiers.display + key.uppercased()
    }

    var eventModifiers: EventModifiers { modifiers.eventModifiers }

    struct ModifierFlags: OptionSet, Codable, Equatable {
        let rawValue: Int
        static let command = ModifierFlags(rawValue: 1)
        static let shift   = ModifierFlags(rawValue: 2)
        static let option  = ModifierFlags(rawValue: 4)
        static let control = ModifierFlags(rawValue: 8)

        var display: String {
            var parts: [String] = []
            if contains(.control) { parts.append("⌃") }
            if contains(.option)  { parts.append("⌥") }
            if contains(.shift)   { parts.append("⇧") }
            if contains(.command) { parts.append("⌘") }
            return parts.joined()
        }

        var eventModifiers: EventModifiers {
            var m: EventModifiers = []
            if contains(.command) { m.insert(.command) }
            if contains(.shift)   { m.insert(.shift) }
            if contains(.option)  { m.insert(.option) }
            if contains(.control) { m.insert(.control) }
            return m
        }
    }
}

enum AppAction: String, CaseIterable, Codable {
    case togglePreview = "Toggle Preview"
    case newDocument = "New Document"
    case toggleSidebar = "Toggle Sidebar"
    case save = "Save"
    case openSettings = "Settings"

    var defaultShortcut: ShortcutBinding {
        switch self {
        case .togglePreview:  ShortcutBinding(key: "p", modifiers: [.command, .shift])
        case .newDocument:    ShortcutBinding(key: "n", modifiers: .command)
        case .toggleSidebar:  ShortcutBinding(key: "s", modifiers: [.command, .shift])
        case .save:           ShortcutBinding(key: "s", modifiers: .command)
        case .openSettings:   ShortcutBinding(key: ",", modifiers: .command)
        }
    }

    var displayName: String { rawValue }
}

@Observable
final class ShortcutManager {
    var bindings: [AppAction: ShortcutBinding] = [:]

    static let shared = ShortcutManager()

    private init() {
        load()
    }

    func binding(for action: AppAction) -> ShortcutBinding {
        bindings[action] ?? action.defaultShortcut
    }

    func setBinding(_ binding: ShortcutBinding, for action: AppAction) {
        bindings[action] = binding
        save()
    }

    func reset(_ action: AppAction) {
        bindings.removeValue(forKey: action)
        save()
    }

    func resetAll() {
        bindings = [:]
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "shortcutBindings"),
              let decoded = try? JSONDecoder().decode([AppAction: ShortcutBinding].self, from: data)
        else { return }
        bindings = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(bindings) else { return }
        UserDefaults.standard.set(data, forKey: "shortcutBindings")
    }
}
