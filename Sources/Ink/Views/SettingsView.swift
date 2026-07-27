import SwiftUI
import UniformTypeIdentifiers

enum SettingsPage: Hashable {
    case root, general, typography, sound, export, about, animation, language, shortcuts, plugins
}

struct SettingsView: View {
    @Bindable var viewModel: EditorViewModel
    @Binding var showSidebar: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var navPath: [SettingsPage] = []

    var body: some View {
        VStack(spacing: 0) {
            if let current = navPath.last, current != .root {
                HStack {
                    Button { navPath.removeLast() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch navPath.last ?? .root {
                    case .root: rootPage
                    case .general: generalPage
                    case .typography: typographyPage
                    case .sound: soundPage
                    case .export: exportPage
                    case .animation: animationPage
                    case .shortcuts: shortcutsPage
                    case .plugins: pluginsPage
                    case .language: languagePage
                    case .about: aboutPage
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 400, height: 520)
    }

    // MARK: – Root

    private var rootPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(tr("Settings"))
                    .font(.title2).fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            SettingsNavRow(icon: "gearshape", title: tr("General"), badge: nil) { navPath.append(.general) }
            SettingsNavRow(icon: "textformat", title: tr("Typography"), badge: viewModel.fontName) { navPath.append(.typography) }
            SettingsNavRow(icon: "speaker.wave.2", title: tr("Sound"), badge: viewModel.isSoundEnabled ? "\(Int(viewModel.soundVolume * 100))%" : tr("Off")) { navPath.append(.sound) }
            SettingsNavRow(icon: "square.and.arrow.up", title: tr("Export"), badge: nil) { navPath.append(.export) }
            SettingsNavRow(icon: "film", title: tr("Animation"), badge: viewModel.settings.animationStyle) { navPath.append(.animation) }
            SettingsNavRow(icon: "keyboard", title: tr("Shortcuts"), badge: nil) { navPath.append(.shortcuts) }
            SettingsNavRow(icon: "puzzlepiece.extension", title: tr("Plugins"), badge: nil) { navPath.append(.plugins) }
            SettingsNavRow(icon: "globe", title: tr("Language"), badge: LocalizationManager.shared.language.displayName) { navPath.append(.language) }
            SettingsNavRow(icon: "info.circle", title: tr("About"), badge: nil) { navPath.append(.about) }

            Divider().padding(.vertical, 8)

            Button(tr("Close Settings")) { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
    }

    // MARK: – General

    private var generalPage: some View {
        SettingsPageView(tr("General")) {
            SettingsGroup(tr("Layout")) {
                Toggle(tr("Show sidebar"), isOn: $showSidebar)
            }

            SettingsGroup(tr("Behaviour")) {
                Toggle(tr("Auto‑save documents"), isOn: Bindable(viewModel.settings).isAutoSaveEnabled)
                Toggle(tr("Spell checking"), isOn: Bindable(viewModel.settings).isSpellCheckEnabled)

                Picker(tr("Default font size"), selection: Bindable(viewModel.settings).fontSize) {
                    ForEach([12, 14, 16, 18, 20, 22, 24], id: \.self) { size in
                        Text("\(size) pt").tag(Double(size))
                    }
                }
            }

            SettingsGroup(tr("Window")) {
                Toggle(tr("Hide menu bar in fullscreen"), isOn: Bindable(viewModel.settings).hideMenuBarInFullscreen)
            }
        }
    }

    // MARK: – Typography

    private var typographyPage: some View {
        SettingsPageView(tr("Typography")) {
            SettingsGroup(tr("Font")) {
                Picker(tr("Typeface"), selection: Bindable(viewModel.settings).fontName) {
                    Text("SF Mono").tag("SF Mono")
                    Text("IBM Plex Mono").tag("IBM Plex Mono")
                    Text("Courier Prime").tag("Courier Prime")
                    Text("Menlo").tag("Menlo")
                    Text("Monaco").tag("Monaco")
                }
                .pickerStyle(.radioGroup)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(tr("Size")): \(Int(viewModel.fontSize)) pt")
                    Slider(value: Bindable(viewModel.settings).fontSize, in: 10...40, step: 1)
                    Text("\(tr("Actual")): \(Int(viewModel.actualFontSize)) pt at current window width")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }

            SettingsGroup(tr("Line Height")) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(tr("Line spacing")): ×\(viewModel.settings.lineHeight, specifier: "%.1f")")
                    Slider(value: Bindable(viewModel.settings).lineHeight, in: 1.0...2.5, step: 0.1)
                }
            }

            SettingsGroup(tr("Preview")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The quick brown fox jumps over the lazy dog")
                        .font(.custom(viewModel.fontName, size: max(12, viewModel.actualFontSize * 0.6)))
                        .foregroundStyle(.primary)
                    Text("AaBbCc 1234567890 !@#$%^&*()")
                        .font(.custom(viewModel.fontName, size: max(10, viewModel.actualFontSize * 0.4)))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3))
                .cornerRadius(6)
            }
        }
    }

    // MARK: – Sound

    private var soundPage: some View {
        SettingsPageView(tr("Sound")) {
            SettingsGroup(tr("Sound Engine")) {
                Toggle(tr("Enable sound effects"), isOn: Bindable(viewModel.settings).isSoundEnabled)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(tr("Volume")): \(Int(viewModel.soundVolume * 100))%")
                    Slider(
                        value: Binding(
                            get: { viewModel.soundVolume },
                            set: { viewModel.updateVolume($0) }
                        ),
                        in: 0...1
                    )
                }

                Picker(tr("Engine"), selection: Bindable(viewModel.settings).soundEngine) {
                    Text(tr("Synthesizer")).tag("synth")
                    Text(tr("Sample player")).tag("samples")
                }
                .pickerStyle(.radioGroup)
            }

            if viewModel.settings.soundEngine == "synth" {
                SettingsGroup(tr("Synthesizer Settings")) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(tr("Click frequency")): \(Int(viewModel.settings.clickFrequency)) Hz")
                        Slider(value: Bindable(viewModel.settings).clickFrequency, in: 2000...8000, step: 100)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(tr("Click duration")): \(Int(viewModel.settings.clickDuration * 1000)) ms")
                        Slider(value: Bindable(viewModel.settings).clickDuration, in: 0.002...0.020, step: 0.001)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(tr("Noise amount")): \(Int(viewModel.settings.clickNoise * 100))%")
                        Slider(value: Bindable(viewModel.settings).clickNoise, in: 0...1, step: 0.05)
                    }
                }
            }

            if viewModel.settings.soundEngine == "samples" {
                SettingsGroup(tr("Custom Sounds")) {
                    soundFilePicker(label: tr("Character click"), type: .char)
                    soundFilePicker(label: tr("Space"), type: .space)
                    soundFilePicker(label: tr("Enter"), type: .enter)
                    soundFilePicker(label: tr("Delete"), type: .delete)
                }
            }

            SettingsGroup("Preview") {
                Button(tr("Test sound")) {
                    viewModel.testSound()
                }
                .buttonStyle(.bordered)
                Button(tr("Play all variations")) {
                    viewModel.testAllSounds()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func soundFilePicker(label: String, type: SoundEngine.CharacterType) -> some View {
        HStack {
            Text(label)
            Spacer()
            Button(tr("Choose…")) {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.wav, .mp3, .aiff, UTType(filenameExtension: "m4a")].compactMap { $0 }
                panel.allowsMultipleSelection = false
                guard panel.runModal() == .OK, let url = panel.url else { return }
                viewModel.setCustomSound(type, url: url)
            }
            .buttonStyle(.borderless)
            .font(.caption)
            Button(tr("Reset")) { viewModel.resetCustomSound(type) }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    // MARK: – Export

    private var exportPage: some View {
        SettingsPageView(tr("Export")) {
            SettingsGroup(tr("Formats")) {
                exportButton(icon: "doc.plaintext", title: tr("Plain Text (.txt)"), action: { viewModel.exportTXT(); dismiss() })
                exportButton(icon: "doc.richtext", title: tr("PDF (.pdf)"), action: { viewModel.exportPDF(); dismiss() })
                exportButton(icon: "doc.text", title: tr("Markdown (.md)"), action: { viewModel.exportMarkdown(); dismiss() })
            }

            SettingsGroup(tr("Batch")) {
                Button(tr("Export all documents")) {
                    viewModel.exportAll()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func exportButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).frame(width: 20)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    // MARK: – Animation

    private var animationPage: some View {
        SettingsPageView(tr("Animation")) {
            SettingsGroup(tr("Document Switch")) {
                Picker(tr("Style"), selection: Bindable(viewModel.settings).animationStyle) {
                    Text(tr("Slide down")).tag("slide")
                    Text(tr("Fade")).tag("fade")
                    Text(tr("Scale")).tag("scale")
                    Text(tr("None")).tag("none")
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(tr("Duration")): \(viewModel.settings.animationDuration, specifier: "%.2f")s")
                    Slider(value: Bindable(viewModel.settings).animationDuration, in: 0.1...1.0, step: 0.05)
                }
            }

            SettingsGroup(tr("Preview")) {
                Button(tr("Test Switch Animation")) {
                    // just toggle something to show animation
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: – Shortcuts

    private var shortcutsPage: some View {
        SettingsPageView(tr("Shortcuts")) {
            SettingsGroup(tr("Key Bindings")) {
                ForEach(AppAction.allCases, id: \.rawValue) { action in
                    shortcutRow(action)
                }
            }
            SettingsGroup("") {
                Button(tr("Reset All")) { ShortcutManager.shared.resetAll() }
                    .buttonStyle(.bordered)
            }
        }
    }

    @State private var recordingAction: AppAction?
    @State private var eventMonitor: Any?

    private func shortcutRow(_ action: AppAction) -> some View {
        HStack {
            Text(action.displayName)
                .font(.body)
            Spacer()
            if recordingAction == action {
                Text(tr("Press shortcut..."))
                    .font(.body.monospaced())
                    .foregroundStyle(.tint)
            } else {
                Text(ShortcutManager.shared.binding(for: action).display)
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.4))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            startRecording(action)
        }
        .contextMenu {
            Button(tr("Reset")) { ShortcutManager.shared.reset(action) }
        }
    }

    private func startRecording(_ action: AppAction) {
        recordingAction = action
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            guard recordingAction != nil else {
                if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
                return event
            }
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard let chars = event.charactersIgnoringModifiers?.lowercased().first else { return event }
            if chars == "\u{1b}" {
                recordingAction = nil
                if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
                return nil
            }
            var m = ShortcutBinding.ModifierFlags()
            if mods.contains(.command) { m.insert(.command) }
            if mods.contains(.shift)   { m.insert(.shift) }
            if mods.contains(.option)  { m.insert(.option) }
            if mods.contains(.control) { m.insert(.control) }
            let binding = ShortcutBinding(key: String(chars), modifiers: m)
            ShortcutManager.shared.setBinding(binding, for: action)
            recordingAction = nil
            if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
            return nil
        }
    }

    // MARK: – Plugins

    @State private var selectedPlugin: Plugin?

    private var pluginsPage: some View {
        SettingsPageView(tr("Plugins")) {
            if let plugin = selectedPlugin {
                pluginDetail(plugin)
            } else {
                SettingsGroup(tr("Installed")) {
                    ForEach(PluginManager.shared.plugins) { plugin in
                        pluginRow(plugin)
                    }
                }
                SettingsGroup("") {
                    Button(tr("Reload Plugins")) {
                        PluginManager.shared.reloadPlugins()
                    }
                    .buttonStyle(.bordered)
                }
                SettingsGroup(tr("Cloud Plugins")) {
                    if PluginManager.shared.cloudPlugins.isEmpty && !PluginManager.shared.isFetchingCloud {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tr("Browse cloud plugins from the community repository."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Button(tr("Browse Cloud…")) {
                                    PluginManager.shared.fetchCloudPlugins()
                                }
                                .buttonStyle(.bordered)
                                if let err = PluginManager.shared.cloudPluginError {
                                    Text(err)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    } else if PluginManager.shared.isFetchingCloud {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(tr("Loading…"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(PluginManager.shared.cloudPlugins) { plugin in
                            cloudPluginRow(plugin)
                        }
                        Button(tr("Refresh")) {
                            PluginManager.shared.fetchCloudPlugins()
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.tint)
                    }
                }
            }
        }
    }

    private func pluginRow(_ plugin: Plugin) -> some View {
        Button {
            selectedPlugin = plugin
        } label: {
            HStack(spacing: 10) {
                Image(systemName: plugin.icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(.body)
                    Text(plugin.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if hasSettings(plugin) {
                    Button {
                        selectedPlugin = plugin
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(tr("Settings"))
                    .padding(.trailing, 4)
                }

                Toggle("", isOn: Binding(
                    get: { plugin.enabled },
                    set: { enabled in
                        var p = plugin
                        p.enabled = enabled
                        PluginManager.shared.saveEnabled(p)
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func cloudPluginRow(_ plugin: Plugin) -> some View {
        HStack(spacing: 10) {
            Image(systemName: plugin.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name)
                    .font(.body)
                Text(plugin.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("v\(plugin.version)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if PluginManager.shared.isCloudPluginInstalled(plugin.id) {
                if PluginManager.shared.needsUpdate(plugin) {
                    Button(tr("Update")) {
                        PluginManager.shared.updateCloudPlugin(plugin)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.orange)
                } else {
                    Text("✓")
                        .foregroundStyle(.green)
                        .font(.body)
                }
                Button(tr("Uninstall")) {
                    PluginManager.shared.uninstallCloudPlugin(plugin.id)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.red)
            } else {
                Button(tr("Install")) {
                    PluginManager.shared.installCloudPlugin(plugin)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private func hasSettings(_ plugin: Plugin) -> Bool {
        plugin.settingsSchema?.isEmpty == false
    }

    private func pluginDetail(_ plugin: Plugin) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button { selectedPlugin = nil } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(tr("Back"))
                    }
                    .font(.body)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: plugin.icon)
                            .font(.title)
                            .foregroundStyle(.tint)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(plugin.name)
                                .font(.title2).fontWeight(.semibold)
                            Text(plugin.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Label("\(tr("Version")) \(plugin.version)", systemImage: "tag")
                        Spacer()
                        Label(plugin.type.rawValue.capitalized, systemImage: plugin.type == .local ? "externaldrive" : "cloud")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let schema = plugin.settingsSchema, !schema.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 12) {
                            Text(tr("Settings"))
                                .font(.headline)
                            ForEach(schema) { def in
                                pluginSettingRow(plugin, def)
                            }
                        }
                    }

                    if plugin.hasActions == true {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tr("Actions"))
                                .font(.headline)
                            ForEach(PluginManager.shared.actions.filter { $0.pluginId == plugin.id }) { action in
                                Button(action: action.handler) {
                                    Label(action.title, systemImage: action.icon)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(16)
            }
        }
    }

    private func pluginSettingRow(_ plugin: Plugin, _ def: PluginSettingDefinition) -> some View {
        let value = Binding(
            get: { PluginManager.shared.setting(for: plugin.id, key: def.key) },
            set: {
                PluginManager.shared.setSetting($0, for: plugin.id, key: def.key)
                PluginManager.shared.reHighlight()
            }
        )

        return VStack(alignment: .leading, spacing: 4) {
            Text(def.label)
                .font(.subheadline)
            switch def.type {
            case .text:
                TextField(def.label, text: value)
                    .textFieldStyle(.roundedBorder)
            case .number:
                TextField(def.label, value: Binding(
                    get: { Int(value.wrappedValue) ?? 0 },
                    set: { value.wrappedValue = "\($0)" }
                ), formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            case .bool:
                Toggle(def.label, isOn: Binding(
                    get: { value.wrappedValue == "true" },
                    set: { value.wrappedValue = $0 ? "true" : "false" }
                ))
            case .select:
                Picker(def.label, selection: value) {
                    ForEach(def.options ?? [], id: \.self) { opt in
                        Text(opt).tag(opt)
                    }
                }
                .pickerStyle(.menu)
            case .color:
                ColorPicker(def.label, selection: Binding(
                    get: { Color(hex: value.wrappedValue) ?? .yellow },
                    set: { c in
                        let hex = c.toHex()
                        value.wrappedValue = hex
                        PluginManager.shared.reHighlight()
                    }
                ), supportsOpacity: false)
            }
        }
    }

    // MARK: – Language

    private var languagePage: some View {
        SettingsPageView(tr("Language")) {
            SettingsGroup(tr("App Language")) {
                languageRow(.english)
                languageRow(.russian)
                languageRow(.japanese)
            }

            SettingsGroup("Note") {
                Text(tr("Changing language takes effect immediately for new UI elements. Some text may require app restart."))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: – About

    private var aboutPage: some View {
        SettingsPageView(tr("About")) {
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().frame(width: 64, height: 64)
                Text("Ink").font(.title).fontWeight(.bold)
                Text("\(tr("Version")) 1.0").font(.subheadline).foregroundStyle(.secondary)
                Text(tr("A minimalist writing app for macOS"))
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            SettingsGroup(tr("Credits")) {
                Text(tr("Ink is built with SwiftUI and AppKit."))
                    .font(.caption).foregroundStyle(.secondary)
                Text(tr("Sound synthesizer by Ink Engine."))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: – Helpers

    private func languageRow(_ lang: AppLanguage) -> some View {
        Button(action: { LocalizationManager.shared.language = lang }) {
            HStack {
                Text(lang.displayName).foregroundStyle(.primary)
                Spacer()
                if LocalizationManager.shared.language == lang {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

// MARK: – Reusable Components

struct SettingsNavRow: View {
    let icon: String
    let title: String
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(.secondary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if let badge = badge {
                    Text(badge)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary.opacity(0.5))
                        .cornerRadius(4)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct SettingsPageView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2).fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

            content
        }
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}
