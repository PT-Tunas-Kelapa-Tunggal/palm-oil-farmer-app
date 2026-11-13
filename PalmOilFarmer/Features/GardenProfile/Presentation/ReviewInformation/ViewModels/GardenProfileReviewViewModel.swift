import Foundation
import Observation

/// Review status, timeline and report shown on the profile.
@MainActor
@Observable
final class GardenProfileReviewViewModel {
    private(set) var activeStatus: ReviewStatus?
    private(set) var activeEntries: [ReviewTimelineEntry] = []
    private(set) var activeReport: FertilizerRecommendationReport?
    private(set) var detailEvents: [ProgressionStatusDetailEvent]?
    private var loadID: UUID?

    func load(for gardenID: UUID, repository: any FarmerReviewRepository) async {
        let id = UUID()
        loadID = id
        guard let existing = try? await repository.fetchRequest(for: gardenID), !Task.isCancelled, loadID == id else { return }
        applyUpdate(existing)
    }

    func applyUpdate(_ request: PlantationReviewRequest) {
        activeStatus = request.status
        detailEvents = request.timeline.detailEvents
        activeEntries = request.timeline.entries(for: request.status)
        activeReport = request.makeRecommendationReport()
    }

    func submitted(_ saved: PlantationReviewRequest) {
        loadID = nil
        applyUpdate(saved)
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
