import SwiftUI

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

/// The app supplies a transport; previews can supply a deterministic response.
struct ReviewService {
    var submit: @MainActor (Garden, ReviewContactDetails) async throws -> GardenReview
    var refresh: @MainActor (Garden) async throws -> GardenReview? = { _ in nil }

    static let unavailable = ReviewService(submit: { _, _ in
        throw ReviewServiceError.unavailable
    })
}

private struct ReviewServiceKey: EnvironmentKey {
    static let defaultValue = ReviewService.unavailable
}

extension EnvironmentValues {
    var reviewService: ReviewService {
        get { self[ReviewServiceKey.self] }
        set { self[ReviewServiceKey.self] = newValue }
    }
}
