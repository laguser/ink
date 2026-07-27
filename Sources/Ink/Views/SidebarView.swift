import SwiftUI

struct SidebarView: View {
    @Bindable var store: DocumentStore
    let onSelectDocument: (UUID) -> Void
    let onCreateDocument: () -> Void
    let onDeleteDocument: (UUID) -> Void

    @State private var renamingDocId: UUID?
    @State private var renameText = ""
    @FocusState private var isRenaming: Bool
    @State private var showWorkspaceMenu = false
    @Bindable private var workspaceManager = WorkspaceManager.shared

    var body: some View {
        VStack(spacing: 0) {
            List(selection: selectionBinding) {
                ForEach(store.documents.sorted(by: { $0.updatedAt > $1.updatedAt })) { doc in
                    docRow(doc)
                }
                .onMove { from, to in store.moveDocuments(from, to: to) }
            }
            .listStyle(.sidebar)

            workspaceFooter
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 300)
        .onAppear {
            store.startWatching {}
            store.syncWorkspaceFiles()
            if let url = workspaceManager.activeWorkspace?.url {
                PluginManager.shared.loadPlugins(from: url)
            }
        }
        .onDisappear { store.stopWatching() }
        .onChange(of: workspaceManager.activeWorkspaceId) { _, _ in
            if let url = workspaceManager.activeWorkspace?.url {
                store.syncWorkspaceFiles()
                PluginManager.shared.loadPlugins(from: url)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onCreateDocument) {
                    Image(systemName: "plus").font(.body)
                }
                .help(tr("New Document"))
            }
        }
    }

    private var workspaceFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showWorkspaceMenu = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(workspaceManager.activeWorkspace?.name ?? tr("No Workspace"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showWorkspaceMenu, arrowEdge: .bottom) {
                workspacePopover
            }
        }
        .background(.bar)
    }

    private var workspacePopover: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tr("Workspaces"))
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 8)

            ForEach(workspaceManager.workspaces) { ws in
                Button {
                    workspaceManager.activeWorkspaceId = ws.id
                    store.reloadFromWorkspace()
                    store.syncWorkspaceFiles()
                    showWorkspaceMenu = false
                } label: {
                    HStack {
                        Text(ws.name)
                            .font(.body)
                        Spacer()
                        if ws.id == workspaceManager.activeWorkspaceId {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            Divider().padding(.vertical, 4)

            Button {
                showWorkspaceMenu = false
                createNewWorkspace()
            } label: {
                Label(tr("New Workspace..."), systemImage: "plus")
                    .font(.body)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Button {
                showWorkspaceMenu = false
                addExistingWorkspace()
            } label: {
                Label(tr("Open Folder..."), systemImage: "folder")
                    .font(.body)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if workspaceManager.activeWorkspace != nil {
                if let url = workspaceManager.activeWorkspace?.url {
                    Button {
                        NSWorkspace.shared.open(url)
                        showWorkspaceMenu = false
                    } label: {
                        Label(tr("Open in Finder"), systemImage: "finder")
                            .font(.body)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

                Button(role: .destructive) {
                    if let id = workspaceManager.activeWorkspaceId {
                        workspaceManager.removeWorkspace(id)
                        store.reloadFromWorkspace()
                        store.syncWorkspaceFiles()
                    }
                    showWorkspaceMenu = false
                } label: {
                    Label(tr("Remove Workspace"), systemImage: "trash")
                        .font(.body)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .padding(8)
        .frame(width: 220)
    }

    private func createNewWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.message = "Choose a folder for your new workspace"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let name = url.lastPathComponent
        workspaceManager.addWorkspace(name: name, url: url)
        store.reloadFromWorkspace()
        store.syncWorkspaceFiles()
    }

    private func addExistingWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.message = "Choose a folder with Markdown files"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let name = url.lastPathComponent
        workspaceManager.addWorkspace(name: name, url: url)
        store.reloadFromWorkspace()
        store.syncWorkspaceFiles()
    }

    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { store.activeDocumentId },
            set: { id in if let id = id { onSelectDocument(id) } }
        )
    }

    @ViewBuilder
    private func docRow(_ doc: Document) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
                .font(.caption)

            if renamingDocId == doc.id {
                TextField("", text: $renameText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isRenaming)
                    .onSubmit { finishRename(doc) }
                    .onExitCommand { renamingDocId = nil }
                    .onAppear { isRenaming = true }
            } else {
                Text(doc.title)
                    .lineLimit(1)
                    .font(.system(size: 12))
            }

            Spacer(minLength: 2)
        }
        .tag(doc.id)
        .contextMenu {
            Button(tr("Rename")) { startRename(doc) }
            Button(tr("Duplicate")) { store.duplicateDocument(doc.id) }
            Divider()
            Button(tr("Delete"), role: .destructive) { onDeleteDocument(doc.id) }
        }
    }

    private func startRename(_ doc: Document) {
        renamingDocId = doc.id
        renameText = doc.title
    }

    private func finishRename(_ doc: Document) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { store.renameDocument(doc.id, to: trimmed) }
        renamingDocId = nil
    }
}
