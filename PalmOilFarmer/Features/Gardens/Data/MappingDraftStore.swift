import Foundation
import Observation

struct MappingDraft: Identifiable, Codable {
    var id: UUID { location.id }
    let location: GardenLocation
    var boundary: GardenBoundary
}

@MainActor
@Observable
final class MappingDraftStore {
    private(set) var drafts: [MappingDraft] = []
    var errorMessage: String?
    private let fileURL: URL
    private var loadFailed = false

    init(fileURL: URL = URL.documentsDirectory.appending(path: "mapping-drafts.json")) {
        self.fileURL = fileURL
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                drafts = try JSONDecoder().decode([MappingDraft].self, from: Data(contentsOf: fileURL))
            }
        } catch {
            loadFailed = true
            errorMessage = "Draf pemetaan tidak dapat dibuka. \(error.localizedDescription)"
        }
    }

    func save(_ draft: MappingDraft) -> Bool {
        var updated = drafts.filter { $0.id != draft.id }
        updated.append(draft)
        return persist(updated)
    }

    func remove(id: UUID) -> Bool {
        persist(drafts.filter { $0.id != id })
    }

    private func persist(_ updated: [MappingDraft]) -> Bool {
        guard !loadFailed else { return false }
        do {
            try JSONEncoder().encode(updated).write(to: fileURL, options: .atomic)
            drafts = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Draf belum tersimpan. \(error.localizedDescription)"
            return false
        }
    }
}
