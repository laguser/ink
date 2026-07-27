import Foundation
import AppKit

@Observable
final class PluginManager {
    var plugins: [Plugin] = []
    var actions: [PluginAction] = []
    var showPluginWindow: String?

    private var wordCache: Set<String> = []
    private var pluginSettings: [String: [String: String]] = [:]

    static let shared = PluginManager()

    private init() {}

    // MARK: – Loading

    func loadPlugins(from workspaceURL: URL) {
        let pluginsDir = workspaceURL.appendingPathComponent("plugins")
        guard FileManager.default.fileExists(atPath: pluginsDir.path) else {
            try? FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)
            seedDefaultPlugins(into: pluginsDir)
            return
        }
        var loaded: [Plugin] = []
        let entries = (try? FileManager.default.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        for entry in entries where entry.hasDirectoryPath {
            let metaFile = entry.appendingPathComponent("plugin.json")
            guard let data = try? Data(contentsOf: metaFile),
                  var plugin = try? JSONDecoder().decode(Plugin.self, from: data)
            else { continue }
            plugin.directory = entry.lastPathComponent
            let savedEnabled = UserDefaults.standard.object(forKey: "plugin_enabled_\(plugin.id)") as? Bool
            plugin.enabled = savedEnabled ?? plugin.enabled
            loaded.append(plugin)
            loadSettings(for: plugin.id, from: entry)
        }
        if loaded.isEmpty {
            seedDefaultPlugins(into: pluginsDir)
            return
        }
        plugins = loaded
        rebuildActions()
    }

    func reloadPlugins() {
        guard let url = WorkspaceManager.shared.activeWorkspace?.url else { return }
        loadPlugins(from: url)
    }

    func saveEnabled(_ plugin: Plugin) {
        UserDefaults.standard.set(plugin.enabled, forKey: "plugin_enabled_\(plugin.id)")
        if let idx = plugins.firstIndex(where: { $0.id == plugin.id }) {
            plugins[idx].enabled = plugin.enabled
        }
        rebuildActions()
    }

    // MARK: – Plugin Settings

    func setting(for pluginId: String, key: String) -> String {
        pluginSettings[pluginId]?[key] ?? ""
    }

    func setSetting(_ value: String, for pluginId: String, key: String) {
        if pluginSettings[pluginId] == nil { pluginSettings[pluginId] = [:] }
        pluginSettings[pluginId]?[key] = value
        saveSettings(for: pluginId)
    }

    private func settingsURL(for pluginId: String) -> URL? {
        guard let url = WorkspaceManager.shared.activeWorkspace?.url else { return nil }
        let dir = url.appendingPathComponent("plugins/\(pluginId)")
        return dir.appendingPathComponent("settings.json")
    }

    private func loadSettings(for pluginId: String, from dir: URL) {
        let url = dir.appendingPathComponent("settings.json")
        guard let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return }
        pluginSettings[pluginId] = dict
    }

    private func saveSettings(for pluginId: String) {
        guard let url = settingsURL(for: pluginId),
              let data = try? JSONEncoder().encode(pluginSettings[pluginId])
        else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: – Plugin Actions

    private func rebuildActions() {
        actions.removeAll()
    }

    // MARK: – Plugin Windows

    func windowContent(for pluginId: String) -> PluginWindowContent? {
        PluginWindowContent(
            title: (plugins.first { $0.id == pluginId })?.name ?? "",
            body: (plugins.first { $0.id == pluginId })?.description ?? ""
        )
    }

    // MARK: – Autocomplete

    func autocompleteSuggestions(for prefix: String, in text: String) -> [String] {
        guard isPluginEnabled("autocomplete") else { return [] }
        let p = prefix.lowercased()
        guard p.count >= 2 else { return [] }
        buildWordCache(from: text)
        return wordCache
            .filter { $0.lowercased().hasPrefix(p) && $0.lowercased() != p }
            .sorted { $0.lowercased() < $1.lowercased() }
            .prefix(8)
            .map { String($0) }
    }

    // MARK: – Word Highlighter

    private var highlightedWord: String?
    private weak var lastHighlightedStorage: NSTextStorage?

    func highlightSelection(word: String?, in textStorage: NSTextStorage?) {
        guard isPluginEnabled("wordhighlighter") else {
            clearHighlights(in: textStorage)
            return
        }
        clearHighlights(in: textStorage)
        guard let word = word, word.count >= 2 else {
            highlightedWord = nil
            lastHighlightedStorage = nil
            return
        }
        highlightedWord = word.lowercased()
        lastHighlightedStorage = textStorage
        applyHighlights(in: textStorage)
    }

    func reHighlight() {
        guard let storage = lastHighlightedStorage, highlightedWord != nil else { return }
        clearHighlights(in: storage)
        applyHighlights(in: storage)
    }

    private func applyHighlights(in textStorage: NSTextStorage?) {
        guard let storage = textStorage, let word = highlightedWord, word.count >= 2 else { return }
        let highlightColor = highlightColor(for: "wordhighlighter")
        let nsText = storage.string as NSString
        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let found = nsText.range(of: word, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange)
            if found.location == NSNotFound { break }
            let prevChar: Bool = {
                guard found.location > 0 else { return true }
                let c = nsText.character(at: found.location - 1)
                guard let s = UnicodeScalar(c) else { return true }
                return !CharacterSet.alphanumerics.contains(s)
            }()
            let nextChar: Bool = {
                let end = found.location + found.length
                guard end < nsText.length else { return true }
                let c = nsText.character(at: end)
                guard let s = UnicodeScalar(c) else { return true }
                return !CharacterSet.alphanumerics.contains(s)
            }()
            let isWord = prevChar && nextChar
            if isWord {
                storage.addAttribute(.backgroundColor, value: highlightColor, range: found)
            }
            searchRange.location = found.location + found.length
            searchRange.length = nsText.length - searchRange.location
        }
    }

    private func clearHighlights(in textStorage: NSTextStorage?) {
        guard let storage = textStorage, storage.length > 0 else { return }
        storage.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: storage.length))
    }

    private func highlightColor(for pluginId: String) -> NSColor {
        let hex = setting(for: pluginId, key: "highlightColor")
        if !hex.isEmpty, let color = NSColor(hex: hex) { return color }
        return NSColor.yellow.withAlphaComponent(0.35)
    }

    // MARK: – Particles

    func emitParticles(at textView: NSTextView, cursor location: Int) {
        guard isPluginEnabled("particles"), let layer = textView.layer else { return }
        let len = (textView.string as NSString).length
        guard len > 0, location != NSNotFound else { return }
        let safeLoc = min(max(location, 0), len - 1)
        let rect = textView.firstRect(forCharacterRange: NSRange(location: safeLoc, length: 0), actualRange: nil)
        guard rect != .zero else { return }
        let windowRect = textView.window?.convertFromScreen(rect) ?? .zero
        let viewRect = textView.convert(windowRect, from: nil)

        let center = CGPoint(x: viewRect.midX, y: viewRect.midY)
        let colors: [CGColor] = [
            .init(red: 1, green: 0.3, blue: 0.3, alpha: 1),
            .init(red: 0.3, green: 0.6, blue: 1, alpha: 1),
            .init(red: 0.3, green: 1, blue: 0.5, alpha: 1),
            .init(red: 1, green: 0.8, blue: 0.2, alpha: 1),
            .init(red: 0.8, green: 0.3, blue: 1, alpha: 1),
        ]

        for _ in 0..<6 {
            let particle = CALayer()
            let size = CGFloat.random(in: 3...7)
            particle.frame = CGRect(x: center.x - size/2, y: center.y - size/2, width: size, height: size)
            particle.cornerRadius = size / 2
            particle.backgroundColor = colors.randomElement()
            particle.opacity = 1
            layer.addSublayer(particle)

            let dx = CGFloat.random(in: -30...30)
            let dy = CGFloat.random(in: -30...30)
            let duration = Double.random(in: 0.3...0.6)

            let anim = CAKeyframeAnimation(keyPath: "position")
            anim.values = [
                center,
                CGPoint(x: center.x + dx * 0.5, y: center.y + dy * 0.5),
                CGPoint(x: center.x + dx, y: center.y + dy)
            ]
            anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            anim.duration = duration

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.duration = duration * 0.8
            fade.beginTime = duration * 0.2

            let group = CAAnimationGroup()
            group.animations = [anim, fade]
            group.duration = duration
            group.isRemovedOnCompletion = true

            CATransaction.begin()
            CATransaction.setCompletionBlock { particle.removeFromSuperlayer() }
            particle.add(group, forKey: "burst")
            CATransaction.commit()
        }
    }

    // MARK: – Focus Mode

    func updateFocus(in textView: NSTextView, cursor location: Int) {
        guard isPluginEnabled("focusmode"), let storage = textView.textStorage else {
            clearFocus(in: textView)
            return
        }

        let nsText = storage.string as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: location, length: 0))
        let fullRange = NSRange(location: 0, length: nsText.length)

        guard fullRange.length > 0 else { return }

        let dimAlpha: CGFloat = 0.3
        let textColor = NSColor.inkText

        storage.beginEditing()

        if lineRange.length > 0 {
            storage.addAttribute(.foregroundColor, value: textColor, range: lineRange)
        }
        if lineRange.location > 0 {
            let before = NSRange(location: 0, length: lineRange.location)
            storage.addAttribute(.foregroundColor, value: textColor.withAlphaComponent(dimAlpha), range: before)
        }
        let afterLoc = lineRange.location + lineRange.length
        if afterLoc < fullRange.length {
            let after = NSRange(location: afterLoc, length: fullRange.length - afterLoc)
            storage.addAttribute(.foregroundColor, value: textColor.withAlphaComponent(dimAlpha), range: after)
        }

        storage.endEditing()
    }

    private func clearFocus(in textView: NSTextView) {
        guard let storage = textView.textStorage, storage.length > 0 else { return }
        storage.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: storage.length))
    }

    // MARK: – Auto Capitalize

    func transformReplacement(_ string: String, range: NSRange, text: String) -> String {
        guard isPluginEnabled("autocapitalize"), string.count == 1,
              let first = string.first, first.isLetter, first.isLowercase
        else { return string }

        if range.location == 0 { return first.uppercased() }

        let idx = text.index(text.startIndex, offsetBy: range.location)
        let before = text[text.startIndex..<idx]
        let trimmed = before.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasSuffix(".") || trimmed.hasSuffix("!") || trimmed.hasSuffix("?") {
            return first.uppercased()
        }

        return string
    }

    // MARK: – Default plugins

    private func isPluginEnabled(_ id: String) -> Bool {
        plugins.first(where: { $0.id == id })?.enabled ?? false
    }

    private func buildWordCache(from text: String) {
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { $0.count >= 2 }
        wordCache = Set(words)
    }

    private func seedDefaultPlugins(into pluginsDir: URL) {
        let defaults: [Plugin] = [
            Plugin(id: "autocomplete", name: "Auto Complete", description: "Suggests word completions as you type", icon: "text.insert", version: "1.0.0", enabled: true, type: .local, directory: "autocomplete", settingsSchema: nil, hasActions: false),
            Plugin(id: "wordhighlighter", name: "Word Highlighter", description: "Highlights all occurrences of a selected word", icon: "highlighter", version: "1.0.0", enabled: true, type: .local, directory: "wordhighlighter", settingsSchema: [PluginSettingDefinition(key: "highlightColor", label: "Highlight color", type: .color, defaultValue: "#FFEB3B", options: nil)], hasActions: false),
            Plugin(id: "autocapitalize", name: "Auto Capitalize", description: "Capitalizes first letter after period, paragraph, or at start of text", icon: "textformat.alt", version: "1.0.0", enabled: true, type: .local, directory: "autocapitalize", settingsSchema: nil, hasActions: false),
            Plugin(id: "particles", name: "Particles", description: "Colored particle burst from cursor on each keystroke", icon: "sparkles", version: "1.0.0", enabled: false, type: .local, directory: "particles", settingsSchema: nil, hasActions: false),
            Plugin(id: "focusmode", name: "Focus Mode", description: "Highlights current line, dims the rest", icon: "eye", version: "1.0.0", enabled: false, type: .local, directory: "focusmode", settingsSchema: nil, hasActions: false),
        ]
        for plugin in defaults {
            let dir = pluginsDir.appendingPathComponent(plugin.directory)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if let data = try? JSONEncoder().encode(plugin),
               let json = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                try? pretty.write(to: dir.appendingPathComponent("plugin.json"))
            }
            var p = plugin
            let savedEnabled = UserDefaults.standard.object(forKey: "plugin_enabled_\(p.id)") as? Bool
            p.enabled = savedEnabled ?? p.enabled
        }
        plugins = defaults.map { p in
            var p = p
            let savedEnabled = UserDefaults.standard.object(forKey: "plugin_enabled_\(p.id)") as? Bool
            p.enabled = savedEnabled ?? p.enabled
            return p
        }
    }
}

struct PluginWindowContent: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

extension NSColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6, let val = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: CGFloat((val >> 16) & 0xFF) / 255,
            green: CGFloat((val >> 8) & 0xFF) / 255,
            blue: CGFloat(val & 0xFF) / 255,
            alpha: 1
        )
    }
}
