import Foundation
import Observation

@MainActor
protocol GardenProfileDataSource: AnyObject {
    var gardens: [Garden] { get }
    var canDeleteGardens: Bool { get }
    func update(_ garden: Garden) -> Bool
    func delete(_ garden: Garden) -> Bool
}

@MainActor
@Observable
final class GardenProfileViewModel {
    let gardenID: UUID
    var showsDeleteError = false
    private(set) var hasDeleted = false
    private let initialGarden: Garden
    private let source: any GardenProfileDataSource
    private let isActive: () -> Bool
    private let canDeleteNow: () -> Bool
    private let onDeleted: () -> Void

    init(garden: Garden, source: any GardenProfileDataSource,
         isActive: @escaping () -> Bool = { true }, canDeleteNow: @escaping () -> Bool = { true },
         onDeleted: @escaping () -> Void) {
        gardenID = garden.id
        initialGarden = garden
        self.source = source
        self.isActive = isActive
        self.canDeleteNow = canDeleteNow
        self.onDeleted = onDeleted
    }

    // The fallback renders the closing screen after deletion; writes require a live value.
    var garden: Garden { currentGarden ?? initialGarden }
    var isAvailable: Bool { currentGarden != nil && !hasDeleted }
    var fertilizers: [FertilizerRecord] { garden.fertilizerRecords ?? [] }
    var isComplete: Bool { garden.isProfileComplete }
    var canDelete: Bool { source.canDeleteGardens && isAvailable }
    private var currentGarden: Garden? { source.gardens.first { $0.id == gardenID } }

    func saveProfile(harvest: HarvestRecord, frequency: Int, fertilizers: [FertilizerRecord]) -> Bool {
        guard isActive(), !hasDeleted, var updated = currentGarden else { return false }
        updated.harvestRecord = harvest
        updated.fertilizationFrequencyPerYear = frequency
        updated.fertilizerRecords = fertilizers
        updated.profileUpdatedAt = .now
        return source.update(updated)
    }

    func saveFertilizers(_ records: [FertilizerRecord]) -> Bool {
        guard isActive(), !hasDeleted, var updated = currentGarden else { return false }
        updated.fertilizerRecords = records
        updated.profileUpdatedAt = .now
        return source.update(updated)
    }

    func saveHarvest(_ record: HarvestRecord) -> Bool {
        guard isActive(), !hasDeleted, var updated = currentGarden else { return false }
        updated.harvestRecord = record
        updated.profileUpdatedAt = .now
        return source.update(updated)
    }

    func saveDetails(_ edited: Garden) -> Bool {
        guard isActive(), !hasDeleted, edited.id == gardenID, let latest = currentGarden else { return false }
        let updated = Garden(
            id: latest.id, name: edited.name, locationName: latest.locationName, boundary: latest.boundary,
            plantingYear: edited.plantingYear, soilType: edited.soilType, plantingMonth: edited.plantingMonth,
            fertilizerRecords: latest.fertilizerRecords, harvestRecord: latest.harvestRecord,
            review: latest.review, createdAt: latest.createdAt, fertilizationFrequencyPerYear: latest.fertilizationFrequencyPerYear, profileUpdatedAt: latest.profileUpdatedAt
        )
        return source.update(updated)
    }

    func updateReview(_ change: (inout GardenReview) -> Void) {
        guard isActive(), !hasDeleted, var updated = currentGarden, var review = updated.review else { return }
        change(&review)
        updated.review = review
        _ = source.update(updated)
    }

    @discardableResult
    func delete() -> Bool {
        guard !hasDeleted else { return true }
        guard isActive(), canDeleteNow(), canDelete, let currentGarden else { return false }
        guard source.delete(currentGarden) else { showsDeleteError = true; return false }
        hasDeleted = true
        onDeleted()
        return true
    }
}
