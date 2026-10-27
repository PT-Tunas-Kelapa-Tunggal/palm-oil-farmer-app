import Foundation

struct GardenReview: Codable {
    let requestID: String
    let status: ReviewStatus
    let entries: [ReviewTimelineEntry]
    var report: FertilizerRecommendationReport? = nil
    // Optional for compatibility with reviews saved before local simulations were persisted.
    var isLocalSimulation: Bool? = nil

    static func localSimulation(for gardenID: UUID, status: ReviewStatus = .submitted) -> GardenReview {
        GardenReview(requestID: "local-" + gardenID.uuidString, status: status,
                     entries: ReviewTimelineEntry.referenceEntries(for: status),
                     isLocalSimulation: true)
    }
}
