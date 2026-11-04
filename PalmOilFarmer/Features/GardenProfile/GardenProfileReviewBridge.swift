import Foundation
import Observation

/// Existing review presentation while consent/contact/submission migrate in Part 9.
@MainActor
@Observable
final class GardenProfileReviewBridge {
    private(set) var activeStatus: ReviewStatus?
    private(set) var activeEntries: [ReviewTimelineEntry] = []
    private(set) var activeReport: FertilizerRecommendationReport?
    private var loadID: UUID?

    func load(for gardenID: UUID, repository: any FarmerReviewRepository) async {
        let id = UUID()
        loadID = id
        guard let existing = try? await repository.fetchRequest(for: gardenID), !Task.isCancelled, loadID == id else { return }
        activeStatus = existing.status
        activeEntries = existing.timeline.entries(for: existing.status)
        activeReport = existing.makeRecommendationReport()
    }

    func submitted(_ saved: PlantationReviewRequest) {
        activeStatus = saved.status
        activeEntries = saved.timeline.entries(for: saved.status)
    }

    func action(for garden: Garden) -> GardenProfileReviewAction {
        let status = activeStatus ?? garden.review?.status
        switch status {
        case nil: return .request
        case .completed where activeStatus == .completed || (garden.review?.resultsDownloaded ?? false): return .results
        default: return .status
        }
    }
}
