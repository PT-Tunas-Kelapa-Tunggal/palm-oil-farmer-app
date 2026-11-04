import Foundation
import SwiftData
@testable import PalmOilFarmer

@MainActor
func makeTestGardenStore(
    in container: ModelContainer,
    repository: (any FarmerReviewRepository)? = nil
) -> GardenStore {
    AppDependencies(
        modelContainer: container,
        reviewRepository: repository ?? ReviewRepositoryStub()
    ).gardenStore
}

@MainActor
struct ReviewRepositoryStub: FarmerReviewRepository {
    enum Failure: Error { case rejected }
    var requests: [PlantationReviewRequest] = []
    var rejectsSubmission = false

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        if rejectsSubmission { throw Failure.rejected }
        return request
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        requests.first { $0.garden.id == gardenID }
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        requests
    }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
