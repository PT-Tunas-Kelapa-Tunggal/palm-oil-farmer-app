import Foundation

/// Reads and advances the locally simulated review without changing a CloudKit review.
@MainActor
protocol AssessmentReviewRepository {
    func loadReview(for gardenID: UUID) throws -> GardenReview?
    func advanceReview(for gardenID: UUID) throws -> GardenReview?
}
