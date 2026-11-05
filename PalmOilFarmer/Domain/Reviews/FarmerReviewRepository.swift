import Foundation

public protocol FarmerReviewRepository: Sendable {
    /// Submits a new scan review request and returns the saved snapshot.
    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest

    /// Fetches the latest review request for a specific garden.
    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest?

    /// Fetches all review requests created by the farmer.
    func fetchMyRequests() async throws -> [PlantationReviewRequest]

    /// Observes updates for a given garden's review request.
    func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest>
}
