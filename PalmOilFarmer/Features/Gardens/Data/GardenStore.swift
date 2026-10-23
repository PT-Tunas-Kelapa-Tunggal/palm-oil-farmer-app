import Foundation
import Observation

@MainActor
@Observable
final class GardenStore {
    private(set) var gardens: [Garden] = []
    var errorMessage: String?

    private let persistence: GardenPersistence
    // Dismissing an alert must never unlock writes over unreadable existing data.
    private var loadFailed = false

    init(fileURL: URL = URL.documentsDirectory.appending(path: "gardens.json")) {
        persistence = GardenPersistence(fileURL: fileURL)
        do {
            gardens = try persistence.load()
        } catch {
            loadFailed = true
            errorMessage = "Data kebun tidak dapat dibuka. \(error.localizedDescription)"
        }
    }

    /// Persist first so a failed write never appears as a successful registration.
    func add(_ garden: Garden) -> Bool {
        guard !gardens.contains(where: { $0.id == garden.id }) else {
            errorMessage = "Kebun sudah terdaftar."
            return false
        }
        return persist(gardens + [garden])
    }

    func update(_ garden: Garden) -> Bool {
        guard let index = gardens.firstIndex(where: { $0.id == garden.id }) else {
            errorMessage = "Kebun tidak ditemukan."
            return false
        }
        var updated = gardens
        updated[index] = garden
        return persist(updated)
    }

    func delete(_ garden: Garden) -> Bool {
        guard gardens.contains(where: { $0.id == garden.id }) else {
            errorMessage = "Kebun tidak ditemukan."
            return false
        }
        return persist(gardens.filter { $0.id != garden.id })
    }

    private func persist(_ updated: [Garden]) -> Bool {
        guard !loadFailed else {
            errorMessage = "Data lama tidak dapat dibuka. Penyimpanan dihentikan agar data tersebut tidak tertimpa."
            return false
        }
        do {
            try persistence.save(updated)
            gardens = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Kebun belum tersimpan. \(error.localizedDescription)"
            return false
        }
    }
}
