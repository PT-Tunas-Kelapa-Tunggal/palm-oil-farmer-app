#if DEBUG
import SwiftUI

/// Shared, isolated fixtures for the canvases beside each production view.
@MainActor
enum GardenProfileCanvasFixtures {
    static var emptyGarden: Garden {
        var garden = GardenPreviewData.garden
        garden.fertilizerRecords = nil
        garden.harvestRecord = nil
        garden.fertilizationFrequencyPerYear = nil
        garden.review = nil
        return garden
    }

    static var npkRecord: FertilizerRecord {
        FertilizerRecord(name: "NPK", bagWeightKg: nil, bagCount: nil, doseKgPerTree: 0.5,
            composition: FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15))
    }

    static var harvestRecord: HarvestRecord {
        HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 140, averageMonthlyWeightKg: 420)
    }

    static var completeGarden: Garden {
        var garden = emptyGarden
        garden.fertilizerRecords = [npkRecord]
        garden.harvestRecord = harvestRecord
        garden.fertilizationFrequencyPerYear = 2
        return garden
    }

    static func makeEditor(filled: Bool = true) -> GardenProfileEditorViewModel {
        GardenProfileEditorViewModel(garden: filled ? completeGarden : emptyGarden,
            onSave: { _, _, _ in true }, onSaved: {})
    }

    static func makeFlow(complete: Bool) -> GardenProfileFlow {
        let repository = CanvasReviewRepository()
        let store = GardenStore(
            draftRepository: SwiftDataGardenDraftRepository(
                modelContainer: AppConfiguration.makeModelContainer(inMemory: true)),
            repository: repository)
        let garden = complete ? completeGarden : emptyGarden
        store.add(garden)
        return GardenProfileFactory(source: store, reviewRepository: repository,
            reviewRequestFactory: ReviewRequestFactory(submission: SubmitGardenReview(gateway: store)))
            .makeFlow(garden: garden)
    }

    static func content(complete: Bool) -> some View {
        GardenProfileContentView(garden: complete ? completeGarden : emptyGarden,
            referenceMapImage: "ProfileReferenceSatellite", metrics: GardenPreviewData.metrics,
            currentReviewStatus: nil, isComplete: complete,
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
