#if DEBUG
import SwiftUI

/// Shared, isolated fixtures for the canvases beside each production view.
@MainActor
enum GardenProfileCanvasFixtures {
    static var emptyGarden: Garden {
        var garden = Garden(id: UUID(), name: "Belakang Rumah", locationName: "Malang Rapat, Bintan", boundary: GardenPreviewData.boundary, plantingYear: 2016, soilType: .peat)
        garden.fertilizerRecords = nil
        garden.harvestRecord = nil
        garden.fertilizationFrequencyPerYear = nil
        garden.review = nil
        return garden
    }

    static var npkRecord: FertilizerRecord {
        FertilizerRecord(name: "NPK", bagWeightKg: nil, bagCount: nil, doseKgPerTree: 1.0,
            composition: FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15))
    }

    static var harvestRecord: HarvestRecord {
        HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 1050, averageMonthlyWeightKg: 2100)
    }

    static var completeGarden: Garden {
        var garden = emptyGarden
        garden.fertilizerRecords = [npkRecord, FertilizerRecord(name: "Urea", bagWeightKg: nil, bagCount: nil, doseKgPerTree: 0.5)]
        garden.harvestRecord = harvestRecord
        garden.fertilizationFrequencyPerYear = 2
        garden.profileUpdatedAt = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 12))
        return garden
    }

    static func makeEditor(filled: Bool = true) -> GardenProfileEditorViewModel {
        GardenProfileEditorViewModel(garden: filled ? completeGarden : emptyGarden,
            onSave: { _, _, _ in true }, onSaved: {})
    }

    static func makeViewModel(complete: Bool) -> GardenProfileViewModel {
        let repository = CanvasReviewRepository()
        let store = GardenStore(
            draftRepository: SwiftDataGardenDraftRepository(
                modelContainer: AppConfiguration.makeModelContainer(inMemory: true)),
            repository: repository)
        let garden = complete ? completeGarden : emptyGarden
        store.add(garden)
        return GardenProfileFactory(source: GardenProfileRepository(gardens: store), reviewRepository: repository,
            reviewRequestFactory: ReviewRequestFactory(submission: SubmitGardenReview(gateway: store)))
            .makeViewModel(garden: garden)
    }

    static func content(complete: Bool, justSaved: Bool = false) -> some View {
        GardenProfileContentView(garden: complete ? completeGarden : emptyGarden,
            referenceMapImage: "ProfileHiFiMap", metrics: GardenDisplayMetrics(area: "1,7 ha", perimeter: "540 m"),
            profileJustSaved: justSaved, currentReviewStatus: nil, isComplete: complete,
            onBack: {}, onEditGarden: {}, onEditProfile: {}, onReviewAction: {},
            onViewSummary: {}, onViewReviewInformation: {})
    }
}

/// Canvas interactions stay in memory and never reach CloudKit.
private actor CanvasReviewRepository: FarmerReviewRepository {
    private var requests: [UUID: PlantationReviewRequest] = [:]

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        requests[request.garden.id] = request
        return request
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        requests[gardenID]
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        Array(requests.values)
    }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
#endif
