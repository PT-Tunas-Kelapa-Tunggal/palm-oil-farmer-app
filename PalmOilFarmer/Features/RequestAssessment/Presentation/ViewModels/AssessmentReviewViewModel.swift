import Foundation
import Observation

@MainActor
@Observable
final class AssessmentReviewViewModel {
    private let gardenID: UUID
    private let repository: any AssessmentReviewRepository
    let results: AssessmentResultsViewModel
    private(set) var review: GardenReview?
    var showsStatus = false
    var showsReviewError = false
    private(set) var isPresentingReviewCompletion = false
    private var showHistoryAfterConfirmationDismisses = false

    init(gardenID: UUID, repository: any AssessmentReviewRepository,
         results: AssessmentResultsViewModel) {
        self.gardenID = gardenID
        self.repository = repository
        self.results = results
    }

    /// Reload on return from submission, including when the profile stays in the navigation stack.
    func refresh() {
        do {
            review = try repository.loadReview(for: gardenID)
            results.load(for: gardenID)
        } catch {
            showsReviewError = true
        }
    }

    func openReview() {
        guard let review else { return }
        guard review.status == .completed else {
            showsStatus = true
            return
        }
        switch results.state {
        case .ready: results.startDownload()
        case .downloading: results.cancelDownload()
        case .downloaded: break // The simulated receipt has no result file to open.
        }
    }

    func advancePreview() {
        do {
            guard let advanced = try repository.advanceReview(for: gardenID) else { return }
            review = advanced
            if advanced.status == .completed {
                isPresentingReviewCompletion = true
                showsStatus = false
            }
        } catch {
            showsReviewError = true
        }
    }

    func statusDidDismiss() {
        guard isPresentingReviewCompletion else { return }
        results.confirmation = .reviewCompleted
    }

    func viewHistory() {
        showHistoryAfterConfirmationDismisses = true
        results.confirmation = nil
    }

    func confirmationDidDismiss() {
        isPresentingReviewCompletion = false
        guard showHistoryAfterConfirmationDismisses else { return }
        showHistoryAfterConfirmationDismisses = false
        showsStatus = review?.status == .completed
    }
}
