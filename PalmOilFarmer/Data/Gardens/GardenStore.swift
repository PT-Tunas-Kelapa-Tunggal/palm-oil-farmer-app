import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GardenStore {
    private(set) var gardens: [Garden] = []
    private(set) var drafts: [GardenDraft] = []
    var errorMessage: String?
    var isLoading = false

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let repository: any FarmerReviewRepository
    private let domainMapper = PlantationDomainMapper()

    private var localDraftGardens: [Garden] = []
    private var submittedGardens: [Garden] = []

    init(
        modelContainer: ModelContainer = AppConfiguration.makeModelContainer(),
        repository: any FarmerReviewRepository = CloudKitFarmerReviewRepository.shared
    ) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
        self.repository = repository

        loadLocalDrafts()
    }

    /// Reloads all local drafts stored in SwiftData.
    func loadLocalDrafts() {
        let descriptor = FetchDescriptor<DraftPlantationRequest>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let requests = try modelContext.fetch(descriptor)
            drafts = requests.filter { !$0.isBoundaryMapped }.map { $0.toGardenDraft() }
            localDraftGardens = requests.filter { $0.isBoundaryMapped }.map { $0.toGarden() }
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
            submittedGardens = requests.map { domainMapper.toGarden(from: $0) }
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

        let draftModel = DraftPlantationRequest.from(garden: garden)
        modelContext.insert(draftModel)

        if let draftID {
            let fetchDraft = FetchDescriptor<DraftPlantationRequest>(
                predicate: #Predicate { $0.id == draftID }
            )
            if let existing = try? modelContext.fetch(fetchDraft).first {
                modelContext.delete(existing)
            }
        }

        do {
            try modelContext.save()
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
        let draftModel = DraftPlantationRequest.from(draft: draft)
        modelContext.insert(draftModel)
        do {
            try modelContext.save()
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
        let draftID = draft.id
        let fetchDraft = FetchDescriptor<DraftPlantationRequest>(
            predicate: #Predicate { $0.id == draftID }
        )
        guard let existing = try? modelContext.fetch(fetchDraft).first else { return false }
        modelContext.delete(existing)
        do {
            try modelContext.save()
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
        let gardenID = garden.id
        let fetchDraft = FetchDescriptor<DraftPlantationRequest>(
            predicate: #Predicate { $0.id == gardenID }
        )
        if let existing = try? modelContext.fetch(fetchDraft).first {
            existing.name = garden.name
            existing.plantingYear = garden.plantingYear
            existing.plantingMonth = garden.plantingMonth
            existing.soilType = garden.soilType
            existing.boundary = garden.boundary
            existing.fertilizerRecords = garden.fertilizerRecords ?? []
            existing.harvestRecord = garden.harvestRecord
            do {
                try modelContext.save()
                loadLocalDrafts()
                return true
            } catch {
                errorMessage = "Gagal memperbarui draf: \(error.localizedDescription)"
                return false
            }
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
        let gardenID = garden.id
        let fetchDraft = FetchDescriptor<DraftPlantationRequest>(
            predicate: #Predicate { $0.id == gardenID }
        )
        if let existing = try? modelContext.fetch(fetchDraft).first {
            modelContext.delete(existing)
            _ = try? modelContext.save()
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

        // Evict from local SwiftData drafts
        let gardenID = garden.id
        let fetchDraft = FetchDescriptor<DraftPlantationRequest>(
            predicate: #Predicate { $0.id == gardenID }
        )
        if let existing = try? modelContext.fetch(fetchDraft).first {
            modelContext.delete(existing)
            try? modelContext.save()
            loadLocalDrafts()
        }

        // Immediately promote the saved CloudKit record into submittedGardens
        let submittedGarden = domainMapper.toGarden(from: saved)
        submittedGardens.removeAll { $0.id == garden.id }
        submittedGardens.append(submittedGarden)
        combineGardens()

        return saved
    }

    #if DEBUG
    /// Developer mode: clears all SwiftData local drafts.
    func eraseAll() {
        let fetchAll = FetchDescriptor<DraftPlantationRequest>()
        if let all = try? modelContext.fetch(fetchAll) {
            for item in all { modelContext.delete(item) }
            try? modelContext.save()
        }
        drafts = []
        localDraftGardens = []
        submittedGardens = []
        gardens = []
        errorMessage = nil
    }
    #endif
}
