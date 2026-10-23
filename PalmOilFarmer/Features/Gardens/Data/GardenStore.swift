import Foundation
import Observation

@MainActor
@Observable
final class GardenStore {
    private(set) var gardens: [Garden] = []
    private(set) var drafts: [GardenDraft] = []
    var errorMessage: String?

    private let persistence: GardenPersistence
    private let draftPersistence: GardenDraftPersistence
    // Dismissing an alert must never unlock writes over unreadable existing data.
    private var loadFailed = false
    private var draftsLoadFailed = false

    init(fileURL: URL = URL.documentsDirectory.appending(path: "gardens.json")) {
        persistence = GardenPersistence(fileURL: fileURL)
        draftPersistence = GardenDraftPersistence(
            fileURL: fileURL.deletingLastPathComponent().appending(path: "garden-drafts.json")
        )
        do {
            gardens = try persistence.load()
        } catch {
            loadFailed = true
            errorMessage = "Data kebun tidak dapat dibuka. \(error.localizedDescription)"
        }
        do {
            drafts = try draftPersistence.load()
        } catch {
            draftsLoadFailed = true
            errorMessage = errorMessage ?? "Draf kebun tidak dapat dibuka. \(error.localizedDescription)"
        }
    }

    /// Persist first so a failed write never appears as a successful registration.
    /// A completed draft is removed afterwards; failing that only leaves the draft in the list.
    func add(_ garden: Garden, completingDraft draftID: UUID? = nil) -> Bool {
        guard !gardens.contains(where: { $0.id == garden.id }) else {
            errorMessage = "Kebun sudah terdaftar."
            return false
        }
        guard persist(gardens + [garden]) else { return false }
        if let draftID, !draftsLoadFailed {
            let remaining = drafts.filter { $0.id != draftID }
            if (try? draftPersistence.save(remaining)) != nil { drafts = remaining }
        }
        return true
    }

    func addDraft(_ draft: GardenDraft) -> Bool {
        persistDrafts(drafts.filter { $0.id != draft.id } + [draft])
    }

    func deleteDraft(_ draft: GardenDraft) -> Bool {
        persistDrafts(drafts.filter { $0.id != draft.id })
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

    private func persistDrafts(_ updated: [GardenDraft]) -> Bool {
        guard !draftsLoadFailed else {
            errorMessage = "Draf lama tidak dapat dibuka. Penyimpanan dihentikan agar draf tersebut tidak tertimpa."
            return false
        }
        do {
            try draftPersistence.save(updated)
            drafts = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Draf kebun belum tersimpan. \(error.localizedDescription)"
            return false
        }
    }
}
