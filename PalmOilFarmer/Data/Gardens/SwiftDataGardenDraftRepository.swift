import Foundation
import SwiftData

@MainActor
final class SwiftDataGardenDraftRepository: GardenDraftRepository {
    private let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        modelContext = ModelContext(modelContainer)
    }

    func loadDrafts() throws -> GardenDraftSnapshot {
        let descriptor = FetchDescriptor<DraftPlantationRequest>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let requests = try modelContext.fetch(descriptor)
        return GardenDraftSnapshot(
            locations: requests.filter { !$0.isBoundaryMapped }.map { $0.toGardenDraft() },
            gardens: requests.filter { $0.isBoundaryMapped }.map { $0.toGarden() }
        )
    }

    func add(_ garden: Garden, completingDraft draftID: UUID?) throws {
        modelContext.insert(DraftPlantationRequest.from(garden: garden))
        if let draftID, let existing = findDraft(id: draftID) {
            modelContext.delete(existing)
        }
        try modelContext.save()
    }

    func addDraft(_ draft: GardenDraft) throws {
        modelContext.insert(DraftPlantationRequest.from(draft: draft))
        try modelContext.save()
    }

    func update(_ garden: Garden) throws -> Bool {
        guard let existing = findDraft(id: garden.id) else { return false }
        existing.name = garden.name
        existing.plantingYear = garden.plantingYear
        existing.plantingMonth = garden.plantingMonth
        existing.soilType = garden.soilType
        existing.boundary = garden.boundary
        existing.fertilizerRecords = garden.fertilizerRecords ?? []
        existing.harvestRecord = garden.harvestRecord
        try modelContext.save()
        return true
    }

    func deleteDraft(id: UUID) throws -> Bool {
        guard let existing = findDraft(id: id) else { return false }
        modelContext.delete(existing)
        try modelContext.save()
        return true
    }

    #if DEBUG
    func eraseAll() throws {
        let descriptor = FetchDescriptor<DraftPlantationRequest>()
        guard let all = try? modelContext.fetch(descriptor) else { return }
        for item in all { modelContext.delete(item) }
        try modelContext.save()
    }
    #endif

    private func findDraft(id: UUID) -> DraftPlantationRequest? {
        let descriptor = FetchDescriptor<DraftPlantationRequest>(
            predicate: #Predicate { $0.id == id }
        )
        // Preserve the existing lookup behavior; changing error handling is separate work.
        return try? modelContext.fetch(descriptor).first
    }
}
