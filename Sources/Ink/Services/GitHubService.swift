import Foundation

@MainActor
@Observable
final class GitHubService {
    var isSyncing = false
    var lastError: String?
    var syncStatus: SyncStatus = .idle

    private let git = GitShell()

    var repoDir: URL {
        WorkspaceManager.shared.activeWorkspace?.url ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Ink/repo")
    }

    var isCloned: Bool {
        FileManager.default.fileExists(atPath: repoDir.appendingPathComponent(".git").path)
    }

    func setupRepository() async -> Bool {
        let config = GitConfig.shared
        guard config.isConfigured else { return false }

        if isCloned {
            return await pull()
        }

        isSyncing = true
        syncStatus = .syncing
        lastError = nil

        // Ensure the parent directory exists
        try? FileManager.default.createDirectory(at: repoDir.deletingLastPathComponent(), withIntermediateDirectories: true)

        let token = KeychainService.getToken() ?? ""
        let url: String
        if !token.isEmpty {
            let parts = config.displayRepo
            url = "https://\(token)@github.com/\(parts).git"
        } else {
            url = config.fullCloneURL
        }

        if FileManager.default.fileExists(atPath: repoDir.path) {
            try? FileManager.default.removeItem(at: repoDir)
        }

        let result = git.run(command: "clone \(url.shellEscaped) \(repoDir.path.shellEscaped)")

        if result.exitCode == 0 {
            syncStatus = .idle
            isSyncing = false
            config.lastSyncDate = Date()
            return true
        } else {
            lastError = result.output
            syncStatus = .error
            isSyncing = false
            return false
        }
    }

    func pull() async -> Bool {
        guard isCloned else { return await setupRepository() }

        isSyncing = true
        syncStatus = .syncing

        let result = git.run(in: repoDir.path, command: "pull --rebase")

        if result.exitCode == 0 {
            syncStatus = .idle
            isSyncing = false
            GitConfig.shared.lastSyncDate = Date()
            return true
        } else {
            lastError = result.output
            syncStatus = .error
            isSyncing = false
            return false
        }
    }

    func push() async -> Bool {
        guard isCloned else { return false }

        isSyncing = true
        syncStatus = .syncing

        let commitResult = git.run(in: repoDir.path, command: "add -A")
        if commitResult.exitCode != 0 {
            lastError = commitResult.output
            syncStatus = .error
            isSyncing = false
            return false
        }

        let dateStr = ISO8601DateFormatter().string(from: Date())
        let msg = "Ink sync \(dateStr)"
        let _ = git.run(in: repoDir.path, command: "commit -m \(msg.shellEscaped) --allow-empty")

        let pushResult = git.run(in: repoDir.path, command: "push")

        if pushResult.exitCode == 0 {
            syncStatus = .idle
            isSyncing = false
            GitConfig.shared.lastSyncDate = Date()
            return true
        } else {
            lastError = pushResult.output
            syncStatus = .error
            isSyncing = false
            return false
        }
    }

    func commitAndPush() async -> Bool {
        guard isCloned else { return false }

        let dir = repoDir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Write documents from the workspace into the repo dir
        if let wsDir = WorkspaceManager.shared.activeWorkspace?.url {
            if let items = try? FileManager.default.contentsOfDirectory(at: wsDir, includingPropertiesForKeys: nil) {
                for item in items {
                    let dest = dir.appendingPathComponent(item.lastPathComponent)
                    try? FileManager.default.copyItem(at: item, to: dest)
                }
            }
        }

        return await push()
    }

    func fullSync() async -> Bool {
        guard await pull() else { return false }
        return await commitAndPush()
    }
}

// MARK: – Git Shell

private struct GitShellResult {
    let output: String
    let exitCode: Int32
}

private struct GitShell {
    @discardableResult
    func run(in directory: String? = nil, command: String) -> GitShellResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["bash", "-c", "git \(command)"]

        if let dir = directory {
            task.currentDirectoryURL = URL(fileURLWithPath: dir)
        }

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return GitShellResult(output: output, exitCode: task.terminationStatus)
        } catch {
            return GitShellResult(output: error.localizedDescription, exitCode: -1)
        }
    }
}

// MARK: – Shell escaping

private extension String {
    var shellEscaped: String {
        "'" + self.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
