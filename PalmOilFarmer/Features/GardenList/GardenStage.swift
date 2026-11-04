import Foundation

/// Where a registered garden is in the farmer's journey; shown as the label on its card.
enum GardenStage: Equatable {
    case incomplete, readyForReview, inReview(ReviewStatus), results(downloaded: Bool)

    /// The farmer has something to do: finish the profile, submit, attend the visit, or open new results.
    var needsAction: Bool {
        switch self {
        case .incomplete, .readyForReview, .inReview(.scheduled), .results(downloaded: false): true
        case .inReview, .results: false
        }
    }
}

extension Garden {
    var stage: GardenStage {
        if let review {
            return review.status == .completed ? .results(downloaded: review.resultsDownloaded) : .inReview(review.status)
        }
        return isProfileComplete ? .readyForReview : .incomplete
    }
}
