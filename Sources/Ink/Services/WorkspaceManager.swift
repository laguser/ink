import Foundation

@Observable
final class WorkspaceManager {
    var workspaces: [Workspace] = []
    var activeWorkspaceId: UUID? {
        didSet { save() }
    }

    var activeWorkspace: Workspace? {
        workspaces.first { $0.id == activeWorkspaceId }
    }

    private static var storeURL: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Ink/workspaces.json")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return url
    }

    static let shared = WorkspaceManager()
    private init() { load() }

    func addWorkspace(name: String, url: URL) {
        let ws = Workspace(name: name, path: url.path)
        workspaces.append(ws)
        activeWorkspaceId = ws.id
        save()
    }

    func removeWorkspace(_ id: UUID) {
        workspaces.removeAll { $0.id == id }
        if activeWorkspaceId == id { activeWorkspaceId = workspaces.first?.id }
        save()
    }

    var needsSetup: Bool { workspaces.isEmpty }

    private func save() {
        guard let data = try? JSONEncoder().encode(workspaces) else { return }
        try? data.write(to: Self.storeURL, options: .atomic)
        if let id = activeWorkspaceId {
            UserDefaults.standard.set(id.uuidString, forKey: "activeWorkspaceId")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.storeURL),
              let decoded = try? JSONDecoder().decode([Workspace].self, from: data)
        else { return }
        workspaces = decoded
        if let idStr = UserDefaults.standard.string(forKey: "activeWorkspaceId"),
           let id = UUID(uuidString: idStr),
           workspaces.contains(where: { $0.id == id }) {
            activeWorkspaceId = id
        } else {
            activeWorkspaceId = workspaces.first?.id
        }
    }
}

struct Workspace: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var path: String

    var url: URL { URL(fileURLWithPath: path) }

    init(id: UUID = UUID(), name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}
