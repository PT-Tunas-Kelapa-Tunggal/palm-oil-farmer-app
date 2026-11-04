#if DEBUG
import Foundation

extension AppDependencies {
    static func preview() -> AppDependencies {
        AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true),
            reviewRepository: PreviewFarmerReviewRepository()
        )
    }
}

private struct PreviewFarmerReviewRepository: FarmerReviewRepository {
    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        throw ReviewServiceError.unavailable
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? { nil }
    func fetchMyRequests() async throws -> [PlantationReviewRequest] { [] }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
#endif
