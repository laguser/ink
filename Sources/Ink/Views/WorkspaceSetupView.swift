import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var workspaceManager = WorkspaceManager.shared
    @State private var workspaceName = "My Thoughts"
    @State private var selectedURL: URL?
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text(tr("Welcome to Ink"))
                .font(.largeTitle).fontWeight(.bold)

            Text(tr("Choose a folder for your workspace.\nAll notes will be stored as Markdown files."))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.body)

            VStack(alignment: .leading, spacing: 12) {
                TextField(tr("Workspace name"), text: $workspaceName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    if let url = selectedURL {
                        Label(url.path, systemImage: "folder.fill")
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text(tr("No folder selected"))
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    Spacer()
                    Button(tr("Browse…")) { showFilePicker = true }
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: 320)

            HStack(spacing: 16) {
                Button(tr("Open existing folder…")) {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.canCreateDirectories = true
                    panel.message = "Choose a folder for your workspace"
                    guard panel.runModal() == .OK, let url = panel.url else { return }
                    selectedURL = url
                    workspaceName = url.lastPathComponent
                }
                .buttonStyle(.bordered)

                Button(tr("Create Workspace")) {
                    guard let url = selectedURL else { return }
                    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    workspaceManager.addWorkspace(name: workspaceName, url: url)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedURL == nil)
            }
        }
        .padding(40)
        .frame(width: 480)
    }
}
