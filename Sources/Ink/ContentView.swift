import SwiftUI

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6, let val = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255
        )
    }

    func toHex() -> String {
        guard let components = cgColor?.components, components.count >= 3 else { return "#FFEB3B" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

struct ContentView: View {
    @State private var viewModel = EditorViewModel()
    @State private var showSettings = false
    @State private var showSidebar = true
    @State private var isMDPreview = false

    var body: some View {
        HSplitView {
            if showSidebar {
                SidebarView(
                    store: viewModel.store,
                    onSelectDocument: { viewModel.selectDocument($0) },
                    onCreateDocument: { viewModel.createDocument() },
                    onDeleteDocument: { viewModel.deleteDocument($0) }
                )
                .frame(minWidth: 180, idealWidth: 220)
            }

            VStack(spacing: 0) {
                GeometryReader { geo in
                    PaperView {
                        if isMDPreview {
                            MarkdownWebView(text: viewModel.text)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            TypewriterTextView(
                                viewModel: viewModel,
                                windowWidth: geo.size.width,
                                isSpellCheckEnabled: viewModel.settings.isSpellCheckEnabled,
                                fontSize: viewModel.actualFontSize,
                                fontName: viewModel.fontName,
                                lineHeight: viewModel.lineHeight
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .id(viewModel.store.activeDocumentId)
                    .animation(.spring(response: viewModel.settings.animationDuration, dampingFraction: 0.85), value: viewModel.store.activeDocumentId)
                    .animation(.spring(response: viewModel.settings.animationDuration, dampingFraction: 0.85), value: isMDPreview)
                    .overlay(alignment: .bottomTrailing) {
                        toggleButton
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                    }
                    .overlay(alignment: .topLeading) {
                        suggestionsOverlay
                    }
                }
                .frame(minWidth: 400)
                    .ignoresSafeArea()

                statusBar
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                viewModel: viewModel,
                showSidebar: $showSidebar
            )
        }
        .overlay(shortcutOverlay)
        .onAppear {
            NSWindow.allowsAutomaticWindowTabbing = false
            PluginManager.shared.loadPlugins(from: WorkspaceManager.shared.activeWorkspace?.url ?? URL(fileURLWithPath: "/tmp"))
        }
    }

    @ViewBuilder
    private var suggestionsOverlay: some View {
        if viewModel.showSuggestions, !viewModel.suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { idx, sug in
                    Button {
                        viewModel.applySuggestion(sug)
                    } label: {
                        HStack {
                            Image(systemName: "text.insert")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(sug)
                                .font(.system(size: 13, design: .monospaced))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(idx == viewModel.selectedSuggestion ? Color.accentColor.opacity(0.15) : .clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 220)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            .offset(x: viewModel.suggestionCursorRect.minX, y: viewModel.suggestionCursorRect.maxY + 4)
        }
    }

    @ViewBuilder
    private var shortcutOverlay: some View {
        ZStack {
            shortcutButton(.openSettings) {
                viewModel.saveImmediately()
                showSettings = true
            }
            shortcutButton(.newDocument) {
                viewModel.createDocument()
            }
            shortcutButton(.toggleSidebar) {
                showSidebar.toggle()
            }
            shortcutButton(.save) {
                viewModel.saveImmediately()
            }
            shortcutButton(.togglePreview) {
                isMDPreview.toggle()
            }
        }
        .frame(width: 0, height: 0)
        .hidden()
    }

    private func shortcutButton(_ action: AppAction, perform: @escaping () -> Void) -> some View {
        let b = ShortcutManager.shared.binding(for: action)
        return Button("", action: perform)
            .keyboardShortcut(KeyEquivalent(b.key.first ?? " "), modifiers: b.modifiers.eventModifiers)
    }

    private var toggleButton: some View {
        Button(action: { isMDPreview.toggle() }) {
            Image(systemName: isMDPreview ? "pencil.line" : "eye")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .help(isMDPreview ? tr("Source") : tr("Preview"))
        .transition(.scale.combined(with: .opacity))
    }

    private var statusBar: some View {
        HStack {
            Text("\(viewModel.wordCount) \(tr("words"))")
            Text("·")
            Text("\(viewModel.charCount) \(tr("chars"))")
            Text("·")
            Text(viewModel.readingTime)
            Spacer()
            pluginActionsBar
            if !PluginManager.shared.actions.isEmpty {
                Text("·")
            }
            Text(viewModel.store.activeDocument?.title ?? "")
                .fontWeight(.medium)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .background(.bar)
        .sheet(item: $pluginSheet) { content in
            pluginSheetView(content)
        }
    }

    @State private var pluginSheet: PluginWindowContent?

    private var pluginActionsBar: some View {
        ForEach(PluginManager.shared.actions) { action in
            Button(action: {
                if let window = PluginManager.shared.windowContent(for: action.pluginId) {
                    pluginSheet = window
                } else {
                    action.handler()
                }
            }) {
                Image(systemName: action.icon)
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help(action.title)
        }
    }

    private func pluginSheetView(_ content: PluginWindowContent) -> some View {
        VStack(spacing: 16) {
            Text(content.title)
                .font(.title2).fontWeight(.semibold)
            Text(content.body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Close") { pluginSheet = nil }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.escape)
        }
        .padding(30)
        .frame(width: 320)
    }
}
