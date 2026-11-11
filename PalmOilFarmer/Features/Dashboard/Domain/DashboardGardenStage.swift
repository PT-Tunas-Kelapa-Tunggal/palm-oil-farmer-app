import Foundation

/// Where a registered garden is in the farmer's journey; shown as the label on its card.
enum DashboardGardenStage: Equatable {
    case incomplete
    case readyForReview
    case inReview(visitScheduled: Bool)
    case results(downloaded: Bool)

    /// The farmer has something to do: finish the profile, submit, attend the visit, or open new results.
    var needsAction: Bool {
        switch self {
        case .incomplete, .readyForReview, .inReview(visitScheduled: true), .results(downloaded: false): true
        case .inReview, .results: false
        }
    }
}
