import Foundation

/// Owns an on-disk JSON array. Keep existing Codable keys compatible with saved files.
struct JSONArrayFile<Element: Codable> {
    let fileURL: URL

    func load() throws -> [Element] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([Element].self, from: Data(contentsOf: fileURL))
    }

    func save(_ elements: [Element]) throws {
        let data = try JSONEncoder().encode(elements)
        try data.write(to: fileURL, options: .atomic)
    }
}

typealias GardenPersistence = JSONArrayFile<Garden>
typealias GardenDraftPersistence = JSONArrayFile<GardenDraft>
