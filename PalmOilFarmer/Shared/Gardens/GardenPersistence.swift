import Foundation

/// Owns the on-disk format. Keep existing Codable keys compatible with saved gardens.
struct GardenPersistence {
    let fileURL: URL

    init(fileURL: URL = URL.documentsDirectory.appending(path: "gardens.json")) {
        self.fileURL = fileURL
    }

    func load() throws -> [Garden] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([Garden].self, from: Data(contentsOf: fileURL))
    }

    func save(_ gardens: [Garden]) throws {
        let data = try JSONEncoder().encode(gardens)
        try data.write(to: fileURL, options: .atomic)
    }
}
