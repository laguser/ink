import Foundation

@Observable
final class Document: Codable, Identifiable {
    let id: UUID
    var title: String
    var text: String
    var cursorPosition: Int
    var createdAt: Date
    var updatedAt: Date
    var folderPath: String  // relative path within workspace (e.g. "My Folder" or "" for root)

    init(id: UUID = UUID(), title: String = "Untitled", text: String = "", cursorPosition: Int = 0, folderPath: String = "") {
        self.id = id
        self.title = title
        self.text = text
        self.cursorPosition = cursorPosition
        self.createdAt = Date()
        self.updatedAt = Date()
        self.folderPath = folderPath
    }

    enum CodingKeys: CodingKey {
        case id, title, text, cursorPosition, createdAt, updatedAt, folderPath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        text = try c.decode(String.self, forKey: .text)
        cursorPosition = try c.decode(Int.self, forKey: .cursorPosition)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        folderPath = try c.decodeIfPresent(String.self, forKey: .folderPath) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(text, forKey: .text)
        try c.encode(cursorPosition, forKey: .cursorPosition)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(folderPath, forKey: .folderPath)
    }
}

extension Document {
    var fileName: String { "\(id.uuidString).md" }
}
