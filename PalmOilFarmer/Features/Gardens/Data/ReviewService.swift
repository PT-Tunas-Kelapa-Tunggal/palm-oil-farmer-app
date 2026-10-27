import SwiftUI

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
