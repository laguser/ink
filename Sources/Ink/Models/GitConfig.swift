import Foundation

@Observable
final class GitConfig {
    var repoPath: String {
        didSet { sync() }
    }
    var isPrivate: Bool {
        didSet { sync() }
    }
    var lastSyncDate: Date? {
        didSet { sync() }
    }

    var isConfigured: Bool { !repoPath.trimmingCharacters(in: .whitespaces).isEmpty }

    var fullCloneURL: String {
        guard isConfigured else { return "" }
        let parts = repoPath.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: ".git", with: "")
        if let token = KeychainService.getToken(), !token.isEmpty {
            return "https://\(token)@github.com/\(parts).git"
        }
        return "https://github.com/\(parts).git"
    }

    var displayRepo: String {
        repoPath.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: ".git", with: "")
    }

    static let shared = GitConfig()

    private init() {
        let defaults = UserDefaults.standard
        repoPath = defaults.string(forKey: "gitRepoPath") ?? ""
        isPrivate = defaults.bool(forKey: "gitIsPrivate")
        if let date = defaults.object(forKey: "gitLastSync") as? Date {
            lastSyncDate = date
        }
    }

    private func sync() {
        let defaults = UserDefaults.standard
        defaults.set(repoPath, forKey: "gitRepoPath")
        defaults.set(isPrivate, forKey: "gitIsPrivate")
        defaults.set(lastSyncDate, forKey: "gitLastSync")
    }
}
