import Foundation
import Observation

/// Core implementation of `GardenDataSource`: SwiftData drafts + CloudKit submissions, merged.
/// Features must depend on `GardenDataSource` (through their own repository), not on this class.
/// Remaining feature-specific conformances live in `App/State/GardenStore+<Feature>.swift`
/// until each feature gets its own repository (docs/ARCHITECTURE.md §7.3).
@MainActor
@Observable
final class GardenStore: GardenDataSource {
    private(set) var gardens: [Garden] = []
    private(set) var drafts: [GardenDraft] = []
    var errorMessage: String?
    var isLoading = false

    private let draftRepository: any GardenDraftRepository
    private let repository: any FarmerReviewRepository

    private var localDraftGardens: [Garden] = []
    private var submittedGardens: [Garden] = []

    init(
        draftRepository: any GardenDraftRepository,
        repository: any FarmerReviewRepository
    ) {
        self.draftRepository = draftRepository
        self.repository = repository

        loadLocalDrafts()
    }

    /// Reloads the unsubmitted local snapshot.
    func loadLocalDrafts() {
        do {
            let snapshot = try draftRepository.loadDrafts()
            drafts = snapshot.locations
            localDraftGardens = snapshot.gardens
            combineGardens()
        } catch {
            errorMessage = "Draf lokal tidak dapat dimuat: \(error.localizedDescription)"
        }
    }

    /// Fetches all submitted gardens from CloudKit Public Database for the active container environment.
    /// CloudKit natively restricts the returned records to those created by the current farmer (_creator ACL).
    func refreshRemote() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let requests = try await repository.fetchMyRequests()
            submittedGardens = requests.map { Garden(reviewRequest: $0) }
            for garden in submittedGardens {
                _ = try? draftRepository.update(garden)
            }
            combineGardens()
        } catch {
            print("[GardenStore] CloudKit fetch status: \(error.localizedDescription)")
        }
    }

    private func combineGardens() {
        // Any garden that has been submitted to CloudKit overrides a local draft with the same ID
        let submittedIDs = Set(submittedGardens.map(\.id))
        let remainingLocal = localDraftGardens.filter { !submittedIDs.contains($0.id) }
        gardens = remainingLocal + submittedGardens
    }

    /// Adds a mapped garden to SwiftData as an unsubmitted local draft.
    /// If completing an unmapped draft ("Lakukan Nanti"), deletes the unmapped draft.
    @discardableResult
    func add(_ garden: Garden, completingDraft draftID: UUID? = nil) -> Bool {
        guard !gardens.contains(where: { $0.id == garden.id }) else {
            errorMessage = "Kebun sudah terdaftar."
            return false
        }

        do {
            try draftRepository.add(garden, completingDraft: draftID)
            loadLocalDrafts()
            return true
        } catch {
            errorMessage = "Kebun belum tersimpan di draf: \(error.localizedDescription)"
            return false
        }
    }

    /// Saves an unmapped location as a draft ("Lakukan Nanti") in SwiftData.
    @discardableResult
    func addDraft(_ draft: GardenDraft) -> Bool {
        do {
            try draftRepository.addDraft(draft)
            loadLocalDrafts()
            return true
        } catch {
            errorMessage = "Draf kebun belum tersimpan: \(error.localizedDescription)"
            return false
        }
    }

    /// Deletes an unmapped draft from SwiftData.
    @discardableResult
    func deleteDraft(_ draft: GardenDraft) -> Bool {
        do {
            guard try draftRepository.deleteDraft(id: draft.id) else { return false }
            loadLocalDrafts()
            return true
        } catch {
            errorMessage = "Draf belum terhapus: \(error.localizedDescription)"
            return false
        }
    }

    /// Updates a local unsubmitted garden in SwiftData.
    @discardableResult
    func update(_ garden: Garden) -> Bool {
        do {
            if try draftRepository.update(garden) {
                loadLocalDrafts()
                return true
            }
        } catch {
            errorMessage = "Gagal memperbarui draf: \(error.localizedDescription)"
            return false
        }

        // If it's already a submitted garden in CloudKit, update in local in-memory representation
        if let index = submittedGardens.firstIndex(where: { $0.id == garden.id }) {
            submittedGardens[index] = garden
            combineGardens()
            return true
        }

        errorMessage = "Kebun tidak ditemukan."
        return false
    }

    /// Deletes a garden. If local draft, removes from SwiftData.
    @discardableResult
    func delete(_ garden: Garden) -> Bool {
        do {
            if try draftRepository.deleteDraft(id: garden.id) {
                loadLocalDrafts()
                return true
            }
        } catch {
            // Existing garden deletion swallows a save failure after finding a
            // local draft. Preserve that policy during dependency extraction.
            loadLocalDrafts()
            return true
        }

        if let index = submittedGardens.firstIndex(where: { $0.id == garden.id }) {
            submittedGardens.remove(at: index)
            combineGardens()
            return true
        }

        return false
    }

    /// Submits a garden review request to CloudKit Public Database.
    /// Upon successful upload, evicts the local draft from SwiftData so CloudKit becomes the sole source of truth.
    @discardableResult
    func submitReview(for garden: Garden, contact: ReviewContactDetails) async throws -> PlantationReviewRequest {
        let request = PlantationReviewRequest(garden: garden, contact: contact)

        let saved = try await repository.submitRequest(request)

        // Keep remote success authoritative even if local cleanup cannot save.
        do {
            if try draftRepository.deleteDraft(id: garden.id) {
                loadLocalDrafts()
            }
        } catch {
            loadLocalDrafts()
        }

        // Immediately promote the saved CloudKit record into submittedGardens
        let submittedGarden = Garden(reviewRequest: saved)
        submittedGardens.removeAll { $0.id == garden.id }
        submittedGardens.append(submittedGarden)
        combineGardens()

        return saved
    }

    #if DEBUG
    /// Developer mode: clears all SwiftData local drafts.
    func eraseAll() {
        try? draftRepository.eraseAll()
        drafts = []
        localDraftGardens = []
        submittedGardens = []
        gardens = []
        errorMessage = nil
    }
    #endif
}
