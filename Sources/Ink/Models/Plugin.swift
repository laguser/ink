import Foundation

struct Plugin: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var icon: String
    var version: String
    var enabled: Bool
    var type: PluginType
    var directory: String
    var settingsSchema: [PluginSettingDefinition]?
    var hasActions: Bool?
}

struct PluginSettingDefinition: Codable, Identifiable, Equatable {
    let key: String
    let label: String
    let type: PluginSettingType
    let defaultValue: String?
    let options: [String]?

    var id: String { key }
}

enum PluginSettingType: String, Codable {
    case text
    case number
    case bool
    case select
    case color
}

struct PluginAction: Identifiable {
    let id: String
    let pluginId: String
    let icon: String
    let title: String
    let handler: () -> Void
}

enum PluginType: String, Codable, CaseIterable {
    case local
    case cloud
}
