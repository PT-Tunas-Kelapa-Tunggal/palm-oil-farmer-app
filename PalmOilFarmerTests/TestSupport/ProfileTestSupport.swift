import Foundation
import Observation
@testable import PalmOilFarmer

@MainActor
func profileGarden() -> Garden {
    Garden(id: UUID(), name: "Kebun", locationName: "Dumai", boundary: GardenBoundary(points: mappingPoints()),
           plantingYear: 2016, soilType: .peat, plantingMonth: 5, createdAt: Date(timeIntervalSince1970: 1_000))
}

@MainActor
func profileFertilizer() -> FertilizerRecord {
    FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 1.5)
}

@MainActor
@Observable
final class ProfileSourceSpy: GardenProfileDataSource {
    var gardens: [Garden]
    var canDeleteGardens = true
    var acceptsUpdates = true
    var acceptsDeletion = true
    var updates: [Garden] = []
    var deletedIDs: [UUID] = []

    init(gardens: [Garden]) { self.gardens = gardens }

    func update(_ garden: Garden) -> Bool {
        updates.append(garden)
        guard acceptsUpdates, let index = gardens.firstIndex(where: { $0.id == garden.id }) else { return false }
        gardens[index] = garden
        return true
    }

    func delete(_ garden: Garden) -> Bool {
        deletedIDs.append(garden.id)
        guard acceptsDeletion, gardens.contains(where: { $0.id == garden.id }) else { return false }
        gardens.removeAll { $0.id == garden.id }
        return true
    }
}

@MainActor
func makeProfileTestFlow(garden: Garden, source: any GardenProfileDataSource) -> GardenProfileFlow {
    GardenProfileFactory(source: source, reviewRepository: ReviewRepositoryStub(),
        submitReview: { PlantationReviewRequest(garden: $0, contact: $1) }).makeFlow(garden: garden)
}

@MainActor
final class ControlledProfileReviewRepository: FarmerReviewRepository {
    enum Failure: Error { case unavailable }
    private var count = 0
    private var requests: [Int: CheckedContinuation<PlantationReviewRequest?, Error>] = [:]
    private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        count += 1
        let id = count
        return try await withCheckedThrowingContinuation {
            requests[id] = $0
            waiters.removeValue(forKey: id)?.resume()
        }
    }

    func waitForRequest(_ id: Int) async {
        if requests[id] != nil { return }
        await withCheckedContinuation { waiters[id] = $0 }
    }

    func finish(_ id: Int, with result: Result<PlantationReviewRequest?, Error>) {
        requests.removeValue(forKey: id)?.resume(with: result)
    }

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest { request }
    func fetchMyRequests() async throws -> [PlantationReviewRequest] { [] }
    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
