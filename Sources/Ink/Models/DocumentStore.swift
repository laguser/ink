import Foundation
import AppKit
import UniformTypeIdentifiers

@Observable
final class DocumentStore {
    var documents: [Document] = []
    var activeDocumentId: UUID?
    var syncStatus: SyncStatus = .idle

    var activeDocument: Document? {
        documents.first { $0.id == activeDocumentId }
    }

    private static var storeURL: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Ink")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.appendingPathComponent("store.json")
    }

    var workspaceDir: URL? {
        WorkspaceManager.shared.activeWorkspace?.url
    }

    init() {
        load()
        if documents.isEmpty {
            trySeedWelcome()
        }
        syncWorkspaceFiles()
    }

    func syncWorkspaceFiles() {
        guard workspaceDir != nil else { return }
        writeDocumentFiles()
    }

    private func trySeedWelcome() {
        guard let url = Bundle.module.url(forResource: "welcome", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            let doc = Document(title: "Welcome to Ink", text: "# Welcome to Ink\n\nStart typing.")
            documents.append(doc)
            activeDocumentId = doc.id
            save()
            return
        }
        let doc = Document(title: "Welcome to Ink", text: text)
        documents.append(doc)
        activeDocumentId = doc.id
        save()
    }

    // MARK: – CRUD

    func createDocument(title: String = "Untitled", folderPath: String = "") -> Document {
        let doc = Document(title: title, folderPath: folderPath)
        documents.append(doc)
        activeDocumentId = doc.id
        save()
        writeDocumentFiles()
        return doc
    }

    func deleteDocument(_ id: UUID) {
        documents.removeAll { $0.id == id }
        if activeDocumentId == id {
            activeDocumentId = documents.first?.id
        }
        save()
        writeDocumentFiles()
    }

    func renameDocument(_ id: UUID, to title: String) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }
        doc.title = title
        save()
    }

    func duplicateDocument(_ id: UUID) {
        guard let original = documents.first(where: { $0.id == id }) else { return }
        let copy = Document(title: "\(original.title) (copy)", text: original.text, folderPath: original.folderPath)
        documents.append(copy)
        save()
        writeDocumentFiles()
    }

    func updateDocumentText(_ id: UUID, text: String) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }
        doc.text = text
        doc.updatedAt = Date()
        if doc.title.isEmpty || doc.title == "Untitled" {
            let firstLine = text.components(separatedBy: "\n").first?.trimmingCharacters(in: .whitespaces) ?? ""
            if !firstLine.isEmpty {
                doc.title = String(firstLine.prefix(60))
            }
        }
        writeDocumentFiles()
    }

    func updateCursorPosition(_ id: UUID, cursor: Int) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }
        doc.cursorPosition = cursor
    }

    func moveDocumentToFolder(_ id: UUID, folder: String) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }
        doc.folderPath = folder
        save()
        writeDocumentFiles()
    }

    func moveDocuments(_ from: IndexSet, to: Int, inFolder: String? = nil) {
        let filtered = inFolder.map { f in documents.enumerated().filter { $0.element.folderPath == f } }
            ?? documents.enumerated().map { $0 }
        let moving = from.map { filtered[$0].offset }.sorted()
        let items = moving.map { documents[$0] }
        for item in items.reversed() {
            documents.removeAll { $0.id == item.id }
        }
        let insertIdx = inFolder.map { f in documents.firstIndex(where: { $0.folderPath >= f }) ?? documents.endIndex }
            ?? to
        documents.insert(contentsOf: items, at: min(insertIdx, documents.endIndex))
        save()
        writeDocumentFiles()
    }

    func createFolder(_ name: String) {
        let dir = workspaceDir?.appendingPathComponent(name) ?? URL(fileURLWithPath: "/tmp/\(name)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // MARK: – Persistence

    private func load() {
        let url = Self.storeURL
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Document].self, from: data)
        else { return }
        documents = decoded
        if let activeId = UserDefaults.standard.string(forKey: "activeDocumentId"),
           let uuid = UUID(uuidString: activeId),
           documents.contains(where: { $0.id == uuid }) {
            activeDocumentId = uuid
        } else {
            activeDocumentId = documents.first?.id
        }
    }

    func save() {
        let url = Self.storeURL
        guard let data = try? JSONEncoder().encode(documents) else { return }
        try? data.write(to: url, options: .atomic)
        if let id = activeDocumentId {
            UserDefaults.standard.set(id.uuidString, forKey: "activeDocumentId")
        }
    }

    func writeDocumentFiles() {
        guard let dir = workspaceDir else {
            print("[DocStore] no workspace dir, skipping file write")
            return
        }
        print("[DocStore] writing \(documents.count) files to \(dir.path)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for doc in documents {
            let folder = doc.folderPath.isEmpty ? dir : dir.appendingPathComponent(doc.folderPath)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let name = doc.title.isEmpty ? "Untitled" : doc.title
            let safe = name.components(separatedBy: CharacterSet(charactersIn: "/:").union(.newlines)).joined()
            let fileURL = folder.appendingPathComponent("\(safe).md")
            try? doc.text.write(to: fileURL, atomically: true, encoding: .utf8)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("[DocStore] wrote \(fileURL.lastPathComponent)")
            } else {
                print("[DocStore] FAILED to write \(fileURL.lastPathComponent)")
            }
        }
    }

    func readDocumentFiles() {
        guard let dir = workspaceDir, FileManager.default.fileExists(atPath: dir.path) else { return }
        let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil)!
        var files: [(URL, String)] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "md" else { continue }
            let folder = url.deletingLastPathComponent().lastPathComponent
            let folderPath = folder == url.path ? "" : url.deletingLastPathComponent().path.replacingOccurrences(of: dir.path + "/", with: "")
            files.append((url, folderPath))
        }
        for (fileURL, folderPath) in files {
            let name = fileURL.deletingPathExtension().lastPathComponent
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            if let id = UUID(uuidString: name),
               let existing = documents.first(where: { $0.id == id }) {
                existing.text = text
                existing.folderPath = folderPath
            } else if let existing = documents.first(where: { $0.title == name }) {
                existing.text = text
                existing.folderPath = folderPath
            } else {
                let doc = Document(title: name, text: text, folderPath: folderPath)
                documents.append(doc)
            }
        }
        save()
    }

    func reloadFromWorkspace() {
        documents.removeAll()
        readDocumentFiles()
        if documents.isEmpty {
            trySeedWelcome()
        }
        activeDocumentId = documents.first?.id
        save()
    }

    func importDocuments(from urls: [URL]) {
        for url in urls {
            guard url.pathExtension == "md",
                  let text = try? String(contentsOf: url, encoding: .utf8)
            else { continue }
            let folder = url.deletingLastPathComponent().path
            let ws = workspaceDir?.path ?? ""
            let folderPath = folder == ws ? "" : String(folder.dropFirst(ws.count + 1))
            if documents.contains(where: { $0.id.uuidString == url.deletingPathExtension().lastPathComponent }) {
                let idStr = url.deletingPathExtension().lastPathComponent
                if let id = UUID(uuidString: idStr), let doc = documents.first(where: { $0.id == id }) {
                    doc.text = text
                    doc.folderPath = folderPath
                }
                continue
            }
            let title = String(text.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
            let idStr = url.deletingPathExtension().lastPathComponent
            let id = UUID(uuidString: idStr) ?? UUID()
            let doc = Document(id: id, title: title.isEmpty ? "Untitled" : title, text: text, folderPath: folderPath)
            documents.append(doc)
        }
        save()
    }

    func startWatching(onChange: @escaping () -> Void) {
        guard let dir = workspaceDir else { return }
        watcher?.cancel()
        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .attrib, .link, .rename], queue: .main)
        source.setEventHandler { [weak self] in
            self?.readDocumentFiles()
            onChange()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }

    func stopWatching() {
        watcher?.cancel()
        watcher = nil
    }

    private var watcher: DispatchSourceFileSystemObject?

    func exportAll() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.message = "Choose a folder to export all documents"
        guard panel.runModal() == .OK, let dir = panel.url else { return }
        for doc in documents {
            let url = dir.appendingPathComponent("\(doc.title).md")
            try? doc.text.write(to: url, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(dir)
    }
}

enum SyncStatus: String, Codable {
    case idle, syncing, error
}
