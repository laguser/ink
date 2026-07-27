import SwiftUI

extension Notification.Name {
    static let inkNewDocument = Notification.Name("inkNewDocument")
}

private func cutFromKeyWindow() {
    (NSApplication.shared.keyWindow?.firstResponder as? NSTextView)?.cut(nil)
}

private func copyFromKeyWindow() {
    (NSApplication.shared.keyWindow?.firstResponder as? NSTextView)?.copy(nil)
}

private func pasteToKeyWindow() {
    (NSApplication.shared.keyWindow?.firstResponder as? NSTextView)?.paste(nil)
}

private func deleteFromKeyWindow() {
    (NSApplication.shared.keyWindow?.firstResponder as? NSTextView)?.delete(nil)
}

private func selectAllInKeyWindow() {
    (NSApplication.shared.keyWindow?.firstResponder as? NSTextView)?.selectAll(nil)
}

@main
struct InkApp: App {
    @State private var showSetup = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .background(WindowSetupView())
                .sheet(isPresented: $showSetup) {
                    WorkspaceSetupView()
                }
                .task {
                    if WorkspaceManager.shared.needsSetup {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        showSetup = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") {
                    NotificationCenter.default.post(name: .inkNewDocument, object: nil)
                }
                .keyboardShortcut("n")
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { NSApplication.shared.keyWindow?.firstResponder?.undoManager?.undo() }
                    .keyboardShortcut("z")
                Button("Redo") { NSApplication.shared.keyWindow?.firstResponder?.undoManager?.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .pasteboard) {
                Section {
                    Button("Cut") { cutFromKeyWindow() }
                        .keyboardShortcut("x")
                    Button("Copy") { copyFromKeyWindow() }
                        .keyboardShortcut("c")
                    Button("Paste") { pasteToKeyWindow() }
                        .keyboardShortcut("v")
                    Button("Delete") { deleteFromKeyWindow() }
                        .keyboardShortcut(.delete)
                }
                Section {
                    Button("Select All") { selectAllInKeyWindow() }
                        .keyboardShortcut("a")
                }
            }
            CommandGroup(replacing: .windowSize) {
                Button("Close Window") { NSApplication.shared.keyWindow?.close() }
                    .keyboardShortcut("w")
            }
        }
    }
}

struct WindowSetupView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowSetupNSView()
    }
    func updateNSView(_: NSView, context: Context) {}
}

final class WindowSetupNSView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let w = window else { return }
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.styleMask.insert(.fullSizeContentView)
        w.titlebarSeparatorStyle = .none
        w.isMovableByWindowBackground = true
        w.backgroundColor = NSColor(red: 250/255, green: 250/255, blue: 248/255, alpha: 1)
        w.contentView?.wantsLayer = true
    }
}
